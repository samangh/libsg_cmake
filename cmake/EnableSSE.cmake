# Checks for the following CPU flags (and support by compiler)
#
# Components: SSE2 SSE3 SSSE3 SSE41 SSE42 AVX AVX2 AVX512 CLMUL

include(CheckCXXCompilerFlag)
include(check_cpu_flag)

set(SSE_FEATURES SSE42 AVX AVX2 AVX512 CLMUL ARM_CRC ARM_AES ARM_SHA3)

##
## _SSE_set_target
##

function(internal_enable_SSE FEATURE)
  set(options CHECK_WITH_FLAGS)
  set(multiValueArgs "")
  set(oneValueArgs GCC_FLAG CLANG_FLAG MSVC_FLAG TEST_CODE)
  cmake_parse_arguments(PARSE_ARGV 1 ARG "${options}" "${oneValueArgs}" "${multiValueArgs}")

  #Set parameters for teset
  if(ARG_CHECK_WITH_FLAGS)
    if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
      set(CMAKE_REQUIRED_FLAGS "${ARG_MSVC_FLAG}")
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
      set(CMAKE_REQUIRED_FLAGS "${ARG_GCC_FLAG}")
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
      set(CMAKE_REQUIRED_FLAGS "${ARG_CLANG_FLAG}")
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
      set(CMAKE_REQUIRED_FLAGS "${ARG_CLANG_FLAG}")
    endif()
  endif()

  check_cxx_source_compiles("${ARG_TEST_CODE}" HAVE_${FEATURE})

  # Set CXX flags if requested
  if(HAVE_${FEATURE})
    add_compile_definitions(CPU_SUPPORTS_${FEATURE})
    if(NOT CMAKE_CXX_FLAGS MATCHES ".* ${CMAKE_REQUIRED_FLAGS} .*")
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CMAKE_REQUIRED_FLAGS} " PARENT_SCOPE)
    endif()
    if(NOT CMAKE_C_FLAGS MATCHES ".* ${CMAKE_REQUIRED_FLAGS} .*")
      set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_REQUIRED_FLAGS} " PARENT_SCOPE)
    endif()
  endif()

  set(CPU_SUPPORTS_${FEATURE} ${HAVE_${FEATURE}} PARENT_SCOPE)
endfunction()

function(internal_check_sse FEATURE)
  set(options CHECK_WITH_FLAGS)
  set(multiValueArgs "")
  set(oneValueArgs "")
  cmake_parse_arguments(PARSE_ARGV 1 ARG "${options}" "${oneValueArgs}" "${multiValueArgs}")

  if(ARG_CHECK_WITH_FLAGS)
    set(CHECK_WITH_FLAGS "CHECK_WITH_FLAGS")
  endif()

  if(X86)
    if(FEATURE STREQUAL "SSE42")
      internal_enable_SSE(${FEATURE}
        GCC_FLAG "-msse4.2"
        CLANG_FLAG "-msse4.2"
        MSVC_FLAG "/d2archSSE42"
        ${CHECK_WITH_FLAGS}
        TEST_CODE
        "#if defined(_MSC_VER)
         #include <intrin.h>
         #else  // !defined(_MSC_VER)
         #include <cpuid.h>
         #include <nmmintrin.h>
         #endif  // defined(_MSC_VER)

         int main() {
           _mm_crc32_u8(0, 0); _mm_crc32_u32(0, 0);
         #if defined(_M_X64) || defined(__x86_64__)
            _mm_crc32_u64(0, 0);
         #endif // defined(_M_X64) || defined(__x86_64__)
           return 0;
         }")
    elseif(FEATURE STREQUAL "AVX")
      #From https://gist.github.com/UnaNancyOwen/263c243ae1e05a2f9d0e
      internal_enable_SSE(${FEATURE}
        GCC_FLAG "-mavx"
        CLANG_FLAG "-mavx"
        MSVC_FLAG "/arch:AVX"
        ${CHECK_WITH_FLAGS}
        TEST_CODE
        "#include <immintrin.h>
        int main()
        {
          __m256 a, b, c;
          const float src[8] = { 1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f, 7.0f, 8.0f };
          float dst[8];
          a = _mm256_loadu_ps( src );
          b = _mm256_loadu_ps( src );
          c = _mm256_add_ps( a, b );
          _mm256_storeu_ps( dst, c );
          for( int i = 0; i < 8; i++ ){
            if( ( src[i] + src[i] ) != dst[i] ){
              return -1;
            }
          }
          return 0;
        }")
    elseif(FEATURE STREQUAL "AVX2")
      #From https://gist.github.com/UnaNancyOwen/263c243ae1e05a2f9d0e
      internal_enable_SSE(${FEATURE}
        GCC_FLAG "-mavx2"
        CLANG_FLAG "-mavx2"
        MSVC_FLAG "/arch:AVX2"
        ${CHECK_WITH_FLAGS}
        TEST_CODE
        " #include <immintrin.h>
        int main()
        {
          __m256i a, b, c;
          const int src[8] = { 1, 2, 3, 4, 5, 6, 7, 8 };
          int dst[8];
          a =  _mm256_loadu_si256( (__m256i*)src );
          b =  _mm256_loadu_si256( (__m256i*)src );
          c = _mm256_add_epi32( a, b );
          _mm256_storeu_si256( (__m256i*)dst, c );
          for( int i = 0; i < 8; i++ ){
            if( ( src[i] + src[i] ) != dst[i] ){
              return -1;
            }
          }
          return 0;
        }")
    elseif(FEATURE STREQUAL "AVX512")
      internal_enable_SSE(${FEATURE}
        GCC_FLAG "-mavx512"
        CLANG_FLAG "-mavx512"
        MSVC_FLAG "/arch:AVX512"
        ${CHECK_WITH_FLAGS}
        TEST_CODE
        "#include <immintrin.h>
       int main()
       {
         __m512i a = _mm512_set_epi8(0, 0, 0, 0, 0, 0, 0, 0,
                                     0, 0, 0, 0, 0, 0, 0, 0,
                                     0, 0, 0, 0, 0, 0, 0, 0,
                                     0, 0, 0, 0, 0, 0, 0, 0,
                                     0, 0, 0, 0, 0, 0, 0, 0,
                                     0, 0, 0, 0, 0, 0, 0, 0,
                                     0, 0, 0, 0, 0, 0, 0, 0,
                                     0, 0, 0, 0, 0, 0, 0, 0);
         __m512i b = a;
         __mmask64 equality_mask = _mm512_cmp_epi8_mask(a, b, _MM_CMPINT_EQ);
         return 0;
       }")
    elseif(FEATURE STREQUAL "CLMUL")
      internal_enable_SSE(${FEATURE}
        GCC_FLAG "-mpclmul"
        CLANG_FLAG "-mpclmul"
        MSVC_FLAG "/d2archSSE42"
        ${CHECK_WITH_FLAGS}
        TEST_CODE
        "#include <immintrin.h>
       int main()
       {
         auto a = _mm_clmulepi64_si128(_mm_cvtsi64_si128(1), _mm_cvtsi64_si128(2), 0);
         return 0;
       }")
    endif()
  endif()

  if(ARM)
    if(FEATURE STREQUAL "ARM_CRC")
      internal_enable_SSE(${FEATURE}
        GCC_FLAG "-mcrc"
        CLANG_FLAG "-mcrc"
        ${CHECK_WITH_FLAGS}
        TEST_CODE
        "#include <cstddef>
       #include <cstdint>

       #include <arm_acle.h>
       #include <arm_neon.h>

       int main()
       {
         uint64_t data;
         auto crc32c = __crc32cd(0, *(uint64_t *)data);
         auto crc32 = __crc32d(0, *(uint64_t *)data);
         return 0;
       }")
    endif()
    if(FEATURE STREQUAL "ARM_AES")
      # Can't enabled this, without doing -march=armv8-1+aes for example
      internal_enable_SSE(${FEATURE}
        ${CHECK_WITH_FLAGS}
        TEST_CODE
        "#include <cstddef>
         #include <cstdint>
         #include <arm_acle.h>
         #include <arm_neon.h>

         int main()
         {
           vmull_p64(0, 0); //part of arm AES extension
           return 0;
         }")
    endif()
    if(FEATURE STREQUAL "ARM_SHA3")
      # Can't enabled this, without doing -march=armv8.2-a+crypto+sha3
      # Mostly supported by Apple Silicon
      internal_enable_SSE(${FEATURE}
        ${CHECK_WITH_FLAGS}
        TEST_CODE
        "#include <arm_acle.h>
        #include <arm_neon.h>
        #include <cstddef>
        #include <cstdint>

        int main() {
            uint64x2_t a, b, c;
            veor3q_u64(a, b, c);
            return 0;
        }")
    endif()
  endif()


  # Propogate variables to parent
  set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} PARENT_SCOPE)
  set(CMAKE_C_FLAGS ${CMAKE_C_FLAGS} PARENT_SCOPE)
  set(CPU_SUPPORTS_${FEATURE} ${CPU_SUPPORTS_${FEATURE}} PARENT_SCOPE)
endfunction()

function(enable_sse FEATURE)
  set(options REQUIRED)
  set(multiValueArgs "")
  set(oneValueArgs "")
  cmake_parse_arguments(PARSE_ARGV 1 ARG "${options}" "${oneValueArgs}" "${multiValueArgs}")

  internal_check_sse(${FEATURE} CHECK_WITH_FLAGS TRUE)
  if(ARG_REQUIRED AND NOT CPU_SUPPORTS_${FEATURE})
    message(SEND_ERROR "SSE feature ${FEATURE} not supported on this system.")
  endif()

  # Propoage variables to parents
  if(CPU_SUPPORTS_${FEATURE})
    set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} PARENT_SCOPE)
    set(CMAKE_C_FLAGS ${CMAKE_C_FLAGS} PARENT_SCOPE)
    set(CPU_SUPPORTS_${FEATURE} ${CPU_SUPPORTS_${FEATURE}} PARENT_SCOPE)
  endif()
endfunction()

# Sets the CPU_SUPPORTS_xxxx definitions, but nothing else
function(check_parent_sse_features)
  foreach(feature in ${SSE_FEATURES})
    internal_check_sse(${feature})

    #Note, we don't propoage the CMAKE_CXX_... variables to parent
    set(CPU_SUPPORTS_${feature} ${CPU_SUPPORTS_${feature}} PARENT_SCOPE)
  endforeach()
endfunction()

