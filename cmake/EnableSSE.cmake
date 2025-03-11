# Checks for the following CPU flags (and support by compiler)
#
# Components: SSE2 SSE3 SSSE3 SSE41 SSE42 AVX AVX2 AVX512 CLMUL

include(CheckCXXCompilerFlag)
include(check_cpu_flag)

set(SSE_FEATURES SSE42 AVX AVX2 AVX512 CLMUL)

##
## _SSE_set_target
##

function(_enable_SSE FEATURE)
  set(options "")
  set(multiValueArgs "")
  set(oneValueArgs GCC_FLAG CLANG_FLAG MSVC_FLAG TEST_CODE)
  cmake_parse_arguments(PARSE_ARGV 1 ARG "${options}" "${oneValueArgs}" "${multiValueArgs}")

  #Set parameters for teset
  if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    set(CMAKE_REQUIRED_FLAGS "${ARG_MSVC_FLAG}")
  elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(CMAKE_REQUIRED_FLAGS "${ARG_GCC_FLAG}")
  elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    set(CMAKE_REQUIRED_FLAGS "${ARG_CLANG_FLAG}")
  elseif (CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    set(CMAKE_REQUIRED_FLAGS "${ARG_CLANG_FLAG}")
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

  set(CPU_SUPPORTS_${FEATURE} TRUE PARENT_SCOPE)
endfunction()

function(_check_sse FEATURE)
  if(FEATURE STREQUAL "SSE42")
    _enable_SSE(${FEATURE}
      GCC_FLAG "-msse4.2"
      CLANG_FLAG "-msse4.2"
      MSVC_FLAG "/d2archSSE42"
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
    _enable_SSE(${FEATURE}
      GCC_FLAG "-mavx"
      CLANG_FLAG "-mavx"
      MSVC_FLAG "/arch:AVX"
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
    _enable_SSE(${FEATURE}
      GCC_FLAG "-mavx2"
      CLANG_FLAG "-mavx2"
      MSVC_FLAG "/arch:AVX2"
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
    _enable_SSE(${FEATURE}
      GCC_FLAG "-mavx512"
      CLANG_FLAG "-mavx512"
      MSVC_FLAG "/arch:AVX512"
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
    _enable_SSE(${FEATURE}
      GCC_FLAG "-mpclmul"
      CLANG_FLAG "-mpclmul"
      MSVC_FLAG "/d2archSSE42"
      TEST_CODE
      "#include <immintrin.h>
       int main()
       {
         auto a = _mm_clmulepi64_si128(_mm_cvtsi64_si128(1), _mm_cvtsi64_si128(2), 0);
         return 0;
       }")
  endif()

  # Propogate variables to parent
  set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} PARENT_SCOPE)
  set(CMAKE_C_FLAGS ${CMAKE_C_FLAGS} PARENT_SCOPE)
  set(CPU_SUPPORTS_${FEATURE} CPU_SUPPORTS_${FEATURE} PARENT_SCOPE)
endfunction()

function(enable_sse FEATURE)
  _check_sse(${FEATURE} TRUE)
  if(NOT CPU_SUPPORTS_${FEATURE})
    message(SEND_ERROR "SSE feature ${FEATURE} not supported on this system.")
  endif()

  # Propoage variables to parent
  set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} PARENT_SCOPE)
  set(CMAKE_C_FLAGS ${CMAKE_C_FLAGS} PARENT_SCOPE)
  set(CPU_SUPPORTS_${FEATURE} CPU_SUPPORTS_${FEATURE} PARENT_SCOPE)
endfunction()

# Sets the CPU_SUPPORTS_xxxx definitions, but nothing else
function(check_parent_sse_features)
  foreach(feature in ${SSE_FEATURES})
    _check_sse(${feature} FALSE)
  endforeach()

  #Note, we don't propoage the CMAKE_CXX_... variables to parent
  set(CPU_SUPPORTS_${FEATURE} CPU_SUPPORTS_${FEATURE} PARENT_SCOPE)
endfunction()

