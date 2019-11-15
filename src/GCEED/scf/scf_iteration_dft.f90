!
!  Copyright 2019 SALMON developers
!
!  Licensed under the Apache License, Version 2.0 (the "License");
!  you may not use this file except in compliance with the License.
!  You may obtain a copy of the License at
!
!      http://www.apache.org/licenses/LICENSE-2.0
!
!  Unless required by applicable law or agreed to in writing, software
!  distributed under the License is distributed on an "AS IS" BASIS,
!  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
!  See the License for the specific language governing permissions and
!  limitations under the License.
!
!=======================================================================

subroutine scf_iteration_dft( img,iDiter,Miter,rion_update,sum1,  &
                              system,energy,  &
                              lg,mg,ng,  &
                              info,info_field,  &
                              poisson,fg,  &
                              cg,mixing,  &
                              stencil,  &
                              srg,srg_ng,   &
                              spsi,shpsi,sttpsi,  &
                              srho,srho_s,  &
                              V_local,sVh,sVxc,sVpsl,xc_func,  &
                              pp,ppg,ppn,  &
                              rho_old,Vlocal_old,  &
                              nref_band,check_conv_esp )
use math_constants, only: pi, zi
use structures
use salmon_parallel, only: nproc_id_global
use salmon_communication, only: comm_is_root, comm_summation, comm_bcast
use salmon_xc
use timer
use scf_iteration_sub
use density_matrix, only: calc_density
use writefield
use global_variables_scf
use salmon_pp, only: calc_nlcc
use hartree_sub, only: hartree
use force_sub
use write_sub
use read_gs
use code_optimization
use initialization_sub
use occupation
use input_pp_sub
use prep_pp_sub
use mixing_sub
use checkpoint_restart_sub
use hamiltonian
use salmon_total_energy
use init_gs, only: init_wf
use density_matrix_and_energy_plusU_sub, only: calc_density_matrix_and_energy_plusU, PLUS_U_ON
implicit none
integer :: ix,iy,iz,ik
integer :: iter,Miter,iob,p1,p2,p5
real(8) :: sum0,sum1
real(8) :: rNebox1,rNebox2

type(s_rgrid) :: lg
type(s_rgrid) :: mg
type(s_rgrid) :: ng
type(s_orbital_parallel) :: info
type(s_field_parallel) :: info_field
type(s_sendrecv_grid) :: srg, srg_ng
type(s_orbital) :: spsi,shpsi,sttpsi
type(s_dft_system) :: system
type(s_poisson) :: poisson
type(s_stencil) :: stencil
type(s_xc_functional) :: xc_func
type(s_scalar) :: srho,sVh,sVpsl,rho_old,Vlocal_old
!type(s_scalar),allocatable :: V_local(:),srho_s(:),sVxc(:)
type(s_scalar) :: V_local(system%nspin),srho_s(system%nspin),sVxc(system%nspin)
type(s_reciprocal_grid) :: fg
type(s_pp_info) :: pp
type(s_pp_grid) :: ppg
type(s_pp_nlcc) :: ppn
type(s_dft_energy) :: energy
type(s_cg)     :: cg
type(s_mixing) :: mixing

logical :: rion_update

integer :: nref_band
!logical,allocatable :: check_conv_esp(:,:,:)
logical :: check_conv_esp(nref_band,system%nk,system%nspin)
real(8),allocatable :: esp_old(:,:,:)
real(8) :: tol_esp_diff

integer :: iDiter(maxntmg)
integer :: i,j, img


allocate( esp_old(system%no,system%nk,system%nspin) ); esp_old=0d0


DFT_Iteration : do iter=1,iDiter(img)

   if(sum1<threshold) cycle DFT_Iteration
   if(calc_mode=='DFT_BAND')then
      if(all(check_conv_esp)) cycle DFT_Iteration
   end if

   Miter=Miter+1

   if(calc_mode/='DFT_BAND')then
      ! for calc_total_energy_periodic
      rion_update = check_rion_update() .or. (iter == 1)
  
      if(temperature>=0.d0 .and. Miter>iditer_notemperature) then
         call ne2mu(energy,system)
      end if
   end if

   call copy_density(Miter,system%nspin,ng,srho_s,mixing)

   call scf_iteration_step(lg,mg,ng,system,info,info_field,stencil,  &
                     srg,srg_ng,spsi,shpsi,srho,srho_s,mst,  &
                     cg,ppg,V_local,  &
                     Miter,iDiterYBCG,  &
                     iditer_nosubspace_diag,ifmst,mixing,iter,  &
                     poisson,fg,sVh,xc_func,ppn,sVxc,energy)

   call allgatherv_vlocal(ng,mg,info_field,system%nspin,sVh,sVpsl,sVxc,V_local)

   call timer_begin(LOG_CALC_TOTAL_ENERGY)
   if( PLUS_U_ON )then
      call calc_density_matrix_and_energy_plusU( spsi,ppg,info,system,energy%E_U )
   end if
   call calc_eigen_energy(energy,spsi,shpsi,sttpsi,system,info,mg,V_local,stencil,srg,ppg)
   if(calc_mode/='DFT_BAND')then
      select case(iperiodic)
      case(0); call calc_Total_Energy_isolated(energy,system,info,ng,pp,srho_s,sVh,sVxc)
      case(3); call calc_Total_Energy_periodic(energy,system,pp,fg,rion_update)
      end select
   end if
   call timer_end(LOG_CALC_TOTAL_ENERGY)

   if(calc_mode=='DFT_BAND')then
      tol_esp_diff=1.0d-5
      esp_old=abs(esp_old-energy%esp)
      check_conv_esp(:,:,:)=.false.
      do ispin=1,system%nspin
      do ik=1,system%nk
         i=0
         j=0
         do iob=1,system%no
            if ( esp_old(iob,ik,ispin) <= tol_esp_diff ) then
               i=i+1
               j=max(j,iob)
               if ( iob <= nref_band ) check_conv_esp(iob,ik,ispin)=.true.
            end if
         end do !io
         if ( ispin==1 .and. ik==1 ) then
            write(*,'(/,1x,"ispin","   ik",2x,"converged bands (total, maximum band index)")')
         end if
         write(*,'(1x,2i5,2x,2i5)') ispin,ik,i,j
      end do !ik
      end do !ispin

      esp_old=energy%esp
  end if

  call timer_begin(LOG_WRITE_GS_RESULTS)

  select case(convergence)
  case('rho_dne')
     sum0=0.d0
!$OMP parallel do reduction(+:sum0) private(iz,iy,ix)
     do iz=ng%is(3),ng%ie(3) 
     do iy=ng%is(2),ng%ie(2)
     do ix=ng%is(1),ng%ie(1)
        sum0 = sum0 + abs(srho%f(ix,iy,iz)-rho_old%f(ix,iy,iz))
     end do
     end do
     end do
     call comm_summation(sum0,sum1,info_field%icomm_all)
     if(ispin==0)then
        sum1 = sum1*system%Hvol/(dble(ifMST(1))*2.d0)
     else if(ispin==1)then
        sum1 = sum1*system%Hvol/dble(ifMST(1)+ifMST(2))
     end if
  case('norm_rho','norm_rho_dng')
     sum0=0.d0
!$OMP parallel do reduction(+:sum0) private(iz,iy,ix)
     do iz=ng%is(3),ng%ie(3) 
     do iy=ng%is(2),ng%ie(2)
     do ix=ng%is(1),ng%ie(1)
        sum0 = sum0 + (srho%f(ix,iy,iz)-rho_old%f(ix,iy,iz))**2
     end do
     end do
     end do
     call comm_summation(sum0,sum1,info_field%icomm_all)
     if(convergence=='norm_rho_dng')then
        sum1 = sum1/dble(lg%num(1)*lg%num(2)*lg%num(3))
     end if
  case('norm_pot','norm_pot_dng')
     sum0=0.d0
!$OMP parallel do reduction(+:sum0) private(iz,iy,ix)
     do iz=ng%is(3),ng%ie(3) 
     do iy=ng%is(2),ng%ie(2)
     do ix=ng%is(1),ng%ie(1)
        sum0 = sum0 + (V_local(1)%f(ix,iy,iz)-Vlocal_old%f(ix,iy,iz))**2
     end do
     end do
     end do
     call comm_summation(sum0,sum1,info_field%icomm_all)
     if(convergence=='norm_pot_dng')then
        sum1 = sum1/dble(lg%num(1)*lg%num(2)*lg%num(3))
     end if
  end select

  if(comm_is_root(nproc_id_global)) then
     write(*,*) '-----------------------------------------------'
     select case(iperiodic)
     case(0)
        if(iflag_diisjump == 1) then
           write(*,'("Diisjump occured. Steepest descent was used.")')
        end if
        write(*,100) Miter,energy%E_tot*2d0*Ry, poisson%iterVh
     case(3)
        write(*,101) Miter,energy%E_tot*2d0*Ry
     end select
100  format(1x,"iter =",i6,5x,"Total Energy =",f19.8,5x,"Vh iteration =",i4)
101  format(1x,"iter =",i6,5x,"Total Energy =",f19.8)

     do ik=1,system%nk
        if(ik<=3)then
           if(iperiodic==3) write(*,*) "k=",ik
           do p5=1,(itotMST+3)/4
              p1=4*(p5-1)+1
              p2=4*p5 ; if ( p2 > itotMST ) p2=itotMST
              write(*,'(1x,4(i5,f15.4,2x))') (iob,energy%esp(iob,ik,1)*2d0*Ry,iob=p1,p2)
           end do
           if(iperiodic==3) write(*,*) 
        end if
     end do

     select case(convergence)
     case('rho_dne' )     ; write(*,200) Miter, sum1
     case('norm_rho')     ; write(*,201) Miter, sum1/a_B**6
     case('norm_rho_dng') ; write(*,202) Miter, sum1/a_B**6
     case('norm_pot')     ; write(*,203) Miter, sum1*(2.d0*Ry)**2/a_B**6
     case('norm_pot_dng') ; write(*,204) Miter, sum1*(2.d0*Ry)**2/a_B**6
     end select
200  format("iter and int_x|rho_i(x)-rho_i-1(x)|dx/nelec        = ",i6,e15.8)
201  format("iter and ||rho_i(ix)-rho_i-1(ix)||**2              = ",i6,e15.8)
202  format("iter and ||rho_i(ix)-rho_i-1(ix)||**2/(# of grids) = ",i6,e15.8)
203  format("iter and ||Vlocal_i(ix)-Vlocal_i-1(ix)||**2              = ",i6,e15.8)
204  format("iter and ||Vlocal_i(ix)-Vlocal_i-1(ix)||**2/(# of grids) = ",i6,e15.8)

  end if

  rNebox1 = 0d0 
!$OMP parallel do reduction(+:rNebox1) private(iz,iy,ix)
  do iz=ng%is(3),ng%ie(3)
  do iy=ng%is(2),ng%ie(2)
  do ix=ng%is(1),ng%ie(1)
     rNebox1 = rNebox1 + srho%f(ix,iy,iz)
  end do
  end do
  end do
  call comm_summation(rNebox1,rNebox2,info_field%icomm_all)
  if(comm_is_root(nproc_id_global))then
     write(*,*) "Ne=",rNebox2*system%Hvol
  end if
  call timer_end(LOG_WRITE_GS_RESULTS)

!$OMP parallel do private(iz,iy,ix)
  do iz=ng%is(3),ng%ie(3)
  do iy=ng%is(2),ng%ie(2)
  do ix=ng%is(1),ng%ie(1)
     rho_old%f(ix,iy,iz)    = srho%f(ix,iy,iz)
     Vlocal_old%f(ix,iy,iz) = V_local(1)%f(ix,iy,iz)
  end do
  end do
  end do

end do DFT_Iteration


end subroutine scf_iteration_dft