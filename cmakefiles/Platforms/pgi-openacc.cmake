### Intel Compiler for Ivy-, Sandy-Bridge
set(ARCH_FLAGS                  "")
set(OPENMP_FLAGS                "-mp -acc -ta=tesla,managed -Minfo=accel")
set(LAPACK_VENDOR_FLAGS         "-Mmkl")
set(ScaLAPACK_VENDOR_FLAGS      "")
set(Fortran_PP_FLAGS            "-cpp")

set(CMAKE_Fortran_COMPILER      "pgf90")
set(CMAKE_C_COMPILER            "pgcc")

#set(General_Fortran_FLAGS       "-nogen-interface -std03 -warn all -diag-disable 6477,7025 -ansi-alias -fno-alias")
set(General_Fortran_FLAGS       "")
set(General_C_FLAGS             "")
set(CMAKE_Fortran_FLAGS_DEBUG   "-O2 -g ${General_Fortran_FLAGS}")
set(CMAKE_C_FLAGS_DEBUG         "-O2 -g ${General_C_FLAGS}")
set(CMAKE_Fortran_FLAGS_RELEASE "-O3 ${General_Fortran_FLAGS}")
set(CMAKE_C_FLAGS_RELEASE       "-O3 ${General_C_FLAGS}")

set(USE_MPI_DEFAULT             ON)

########
# CMake Platform-specific variables
########
set(CMAKE_SYSTEM_NAME "Linux" CACHE STRING "Cross-compiling for Intel Ivy-, Sandy-Bridge (AVX)")
set(CMAKE_SYSTEM_PROCESSOR "avx")
