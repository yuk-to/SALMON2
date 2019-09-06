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
subroutine calcVpsl_periodic(lg,fg,matrix_A)
  use structures,      only: s_rgrid, s_reciprocal_grid
  use salmon_parallel, only: nproc_group_global, nproc_size_global, nproc_id_global
  use salmon_communication, only: comm_bcast, comm_summation, comm_is_root
  use prep_pp_sub, only: calc_vloc,calc_vpsl
  use scf_data
  use new_world_sub
  use allocate_psl_sub
  use allocate_mat_sub
  implicit none
  type(s_rgrid),intent(in) :: lg
  type(s_reciprocal_grid),intent(inout) :: fg
  real(8),intent(in) :: matrix_A(3,3)
  
  integer :: ix,iy,iz,ak
  integer :: n
  real(8) :: aLxyz
  integer :: NG_s,NG_e
  integer :: NG_l_s_para,NG_l_e_para
  integer :: numtmp
  complex(8),parameter :: zI=(0.d0,1.d0)
  integer :: lx(lg%num(1)*lg%num(2)*lg%num(3))
  integer :: ly(lg%num(1)*lg%num(2)*lg%num(3))
  integer :: lz(lg%num(1)*lg%num(2)*lg%num(3))
  complex(8),allocatable :: zdVG_ion_tmp2(:,:)
  complex(8),allocatable :: zrhoG_ion_tmp2(:)
  real(8),allocatable :: vpsl_ia(:,:)
  real(8),allocatable :: vpsl_tmp2(:)
  integer :: i,ia
  real(8) :: hx,hy,hz
 
  if(.not.allocated(fg%zrhoG_ion_tmp)) allocate(fg%zrhoG_ion_tmp(fg%ng))
  if(.not.allocated(fg%zdVG_ion_tmp)) allocate(fg%zdVG_ion_tmp(fg%ng,nelem))

  NG_s=1
  NG_e=lg%num(1)*lg%num(2)*lg%num(3)
  
  numtmp=(NG_e-NG_s+1)/nproc_size_global
  
  NG_l_s_para = nproc_id_global*numtmp+1
  NG_l_e_para = (nproc_id_global+1)*numtmp
  if(nproc_id_global==nproc_size_global-1) NG_l_e_para=NG_e

  allocate(zdVG_ion_tmp2(ng_l_s_para:ng_l_e_para,MKI))
 
  call calc_vloc(pp,zdVG_ion_tmp2,fg%Gx,fg%Gy,fg%Gz,ng_e,ng_l_s_para,ng_l_e_para,fg%iGzero)

  fg%zdVG_ion_tmp=0.d0
  do ak=1,MKI
    do n=ng_l_s_para,ng_l_e_para
      fg%zdVG_ion_tmp(n,ak)=zdVG_ion_tmp2(n,ak)
    end do
  end do

  call comm_summation(fg%zdVG_ion_tmp,fg%zdVG_ion,(NG_e-NG_s+1)*MKI,nproc_group_global)

  
  hx=Hgs(1) 
  hy=Hgs(2) 
  hz=Hgs(3)
  aLxyz=Hvol*dble(lg%num(1)*lg%num(2)*lg%num(3))

  do iz=1,lg%num(3)
  do iy=1,lg%num(2)
  do ix=1,lg%num(1)
    i=(iz-1)*lg%num(1)*lg%num(2)+(iy-1)*lg%num(1)+ix
    lx(i)=ix-1
    ly(i)=iy-1
    lz(i)=iz-1
  end do
  end do
  end do
 
  allocate(zrhoG_ion_tmp2(ng_l_s_para:ng_l_e_para))
  allocate(vpsl_ia(lg%num(1)*lg%num(2)*lg%num(3),MI))
  allocate(vpsl_tmp2(ng_s:ng_e))

  call calc_vpsl(pp,zrhoG_ion_tmp2,vpsl_ia,vpsl_tmp2,zdVG_ion_tmp2,  &
                     fg%iGzero,fg%Gx,fg%Gy,fg%Gz,ng_e,ng_l_s_para,ng_l_e_para,ng_e,alxyz,lx,ly,lz,hx,hy,hz,matrix_A)

  deallocate(zdVG_ion_tmp2)

  fg%zrhoG_ion_tmp=0.d0
  fg%zrhoG_ion_tmp(ng_l_s_para:ng_l_e_para)=zrhoG_ion_tmp2(ng_l_s_para:ng_l_e_para)

  call comm_summation(fg%zrhoG_ion_tmp,fg%zrhoG_ion,NG_e-NG_s+1,nproc_group_global)

  allocate(ppg%Vpsl_atom(mg_sta(1):mg_end(1),mg_sta(2):mg_end(2),mg_sta(3):mg_end(3),MI))

  do iz=mg_sta(3),mg_end(3)
  do iy=mg_sta(2),mg_end(2)
  do ix=mg_sta(1),mg_end(1)
    i=(iz-1)*lg%num(1)*lg%num(2)+(iy-1)*lg%num(1)+ix
    Vpsl(ix,iy,iz)=vpsl_tmp2(i)
    do ia=1,MI
      ppg%Vpsl_atom(ix,iy,iz,ia) = Vpsl_ia(i,ia)
    end do
  enddo
  enddo
  enddo

  return

end subroutine calcVpsl_periodic
