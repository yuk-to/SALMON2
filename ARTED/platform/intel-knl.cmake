### Intel Compiler for Knights-Landing
set(TARGET_SUFFIX               ".mic")

set(ARCH                        "-xMIC-AVX512")
set(SIMD_SET                    "IMCI")
set(OPENMP_FLAGS                "-qopenmp")
set(LAPACK_FLAGS                "-mkl=parallel")
set(ADDITIONAL_MACRO            "")
set(ADDITIONAL_OPTIMIZE_FLAGS   "-qopt-ra-region-strategy=block -ansi-alias -fno-alias")

set(Fortran_FLAGS_General       "-fpp -nogen-interface -std90 -warn all -diag-disable 6187,6477,6916,7025,7416")
set(C_FLAGS_General             "-Wall -diag-disable=10388 -restrict")

set(CMAKE_Fortran_COMPILER      "mpiifort")
set(CMAKE_Fortran_FLAGS_DEBUG   "-O2 -g")
set(CMAKE_Fortran_FLAGS_RELEASE "-O3")
set(CMAKE_C_COMPILER            "mpiicc")
set(CMAKE_C_FLAGS_DEBUG         "-O2 -g")
set(CMAKE_C_FLAGS_RELEASE       "-O3")

set(STENCIL_WITH_C             ON)
set(ENABLE_EXPLICIT_VEC        ON)
set(ENABLE_REDUCE_FOR_MANYCORE ON)
set(ENABLE_SWPREFETCH          ON)


########
# CMake Platform-specific variables
########
set(CMAKE_SYSTEM_NAME "Linux" CACHE STRING "Cross-compiling for Intel Knights-Landing")
set(CMAKE_SYSTEM_PROCESSOR "knl")
