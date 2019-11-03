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
MODULE allocate_mat_sub

use inputoutput, only: iperiodic
use scf_data
implicit none

real(8), allocatable :: vecR(:,:,:,:)
real(8), allocatable :: vecR_tmp(:,:,:,:)

real(8), allocatable :: wk_s_h(:,:,:),wk2_s_h(:,:,:),lap_wk_s_h(:,:,:)

real(8), allocatable :: matbox_m(:,:,:),matbox_m2(:,:,:)
complex(8), allocatable :: cmatbox_m(:,:,:),cmatbox_m2(:,:,:)
real(8), allocatable :: matbox_l(:,:,:),matbox_l2(:,:,:)
complex(8), allocatable :: cmatbox_l(:,:,:),cmatbox_l2(:,:,:)

complex(8), allocatable :: zalpha2(:,:,:,:),zalpha3(:,:,:,:)

real(8),allocatable :: rgrad_wk(:,:,:,:,:,:)

complex(8),allocatable :: cgrad_wk(:,:,:,:,:,:)

real(8), allocatable :: rho_tmp(:,:,:)
real(8), allocatable :: exc_dummy(:,:,:)
real(8), allocatable :: exc_dummy2(:,:,:,:)
real(8), allocatable :: exc_dummy3(:,:,:,:)

CONTAINS

!=======================================================================
!=======================================================================

SUBROUTINE allocate_mat(ng,mg)
  use structures, only: s_rgrid
  implicit none
  type(s_rgrid),intent(in) :: ng,mg

allocate (vecR(3,lg_sta(1):lg_end(1),    &
             lg_sta(2):lg_end(2),      &
             lg_sta(3):lg_end(3)) )

allocate (vecR_tmp(3,lg_sta(1):lg_end(1),    &
             lg_sta(2):lg_end(2),      &
             lg_sta(3):lg_end(3)) )

allocate (matbox_m(mg%is(1):mg%ie(1),    &
             mg%is(2):mg%ie(2),      &
             mg%is(3):mg%ie(3)) )

allocate (matbox_m2(mg%is(1):mg%ie(1),    &
             mg%is(2):mg%ie(2),      &
             mg%is(3):mg%ie(3)) )
allocate (cmatbox_m(mg%is(1):mg%ie(1),    &
             mg%is(2):mg%ie(2),      &
             mg%is(3):mg%ie(3)) )
allocate (cmatbox_m2(mg%is(1):mg%ie(1),    &
             mg%is(2):mg%ie(2),      &
             mg%is(3):mg%ie(3)) )

allocate (matbox_l(lg_sta(1):lg_end(1),    &
             lg_sta(2):lg_end(2),      &
             lg_sta(3):lg_end(3)) )
allocate (matbox_l2(lg_sta(1):lg_end(1),    &
             lg_sta(2):lg_end(2),      &
             lg_sta(3):lg_end(3)) )
allocate (cmatbox_l(lg_sta(1):lg_end(1),    &
             lg_sta(2):lg_end(2),      &
             lg_sta(3):lg_end(3)) )
allocate (cmatbox_l2(lg_sta(1):lg_end(1),    &
             lg_sta(2):lg_end(2),      &
             lg_sta(3):lg_end(3)) )

allocate (wk_s_h(ng%is(1)-Ndh:ng%ie(1)+Ndh,   &
             ng%is(2)-Ndh:ng%ie(2)+Ndh,   &
             ng%is(3)-Ndh:ng%ie(3)+Ndh))
allocate (wk2_s_h(ng%is(1):ng%ie(1),   &
              ng%is(2):ng%ie(2),   &
              ng%is(3):ng%ie(3)))
allocate (lap_wk_s_h(ng%is(1):ng%ie(1),   &
                 ng%is(2):ng%ie(2),   &
                 ng%is(3):ng%ie(3)))

!if(iSCFRT==1.and.yn_opt=='y')then  !necessary??
!  select case(iperiodic)
!  case(0)
!    allocate(rgrad_wk(mg%is(1):mg%ie(1)+1,   &
!                      mg%is(2):mg%ie(2),     &
!                      mg%is(3):mg%ie(3),1:iobnum,k_sta:k_end,3))
!  case(3)
!    allocate(cgrad_wk(mg%is(1):mg%ie(1)+1,   &
!                      mg%is(2):mg%ie(2),     &
!                      mg%is(3):mg%ie(3),1:iobnum,k_sta:k_end,3))
!  end select
!else if(iSCFRT==2.and.(yn_out_rvf_rt=='y'.or.yn_md=='y'))then !necessary??
!  allocate(cgrad_wk(mg%is(1):mg%ie(1)+1,   &
!                    mg%is(2):mg%ie(2),     &
!                    mg%is(3):mg%ie(3),1:iobnum,k_sta:k_end,3))
!end if

allocate (rho_tmp(ng%num(1), ng%num(2), ng%num(3)))
allocate (exc_dummy(ng%num(1), ng%num(2), ng%num(3)))
allocate (exc_dummy2(ng%num(1), ng%num(2), ng%num(3),2))
allocate (exc_dummy3(ng%num(1), ng%num(2), ng%num(3),3))

END SUBROUTINE allocate_mat

!======================================================================

END MODULE allocate_mat_sub
