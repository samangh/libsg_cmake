# The FindSEE file sets the CPU_SUPPORTS_xxx defnitions, if the SSE
# package is imported. But we also want the defnitions o bt set, for
# example if the user manually does CMAKE_CXX_FLGS="-march=haswell" to
# target a specific architecture.
#
# This macro does this.
macro(check_sse_features)
  include(CheckCXXSourceCompiles)

  ##
  ## SSE 4.2
  ##
  check_cxx_source_compiles("
    #if defined(_MSC_VER)
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
    }
    " _HAVE_SSE42)

  if(_HAVE_SSE42)
    add_compile_definitions(CPU_SUPPORTS_SSE42)

    foreach(comp in SSE2 SSE3 SSSE3 SSE41)
      set(CPU_SUPPORTS_${comp} TRUE)
    endforeach()
  endif()

  ##
  ## SSSE 3
  ##
  check_cxx_source_compiles("
         #include <tmmintrin.h>
         int main() {
             __m64 a = _mm_abs_pi8(__m64());
             (void)a;
             return 0;
         }
     " _HAVE_SSSE3)

  if(_HAVE_SSSE3)
    add_compile_definitions(CPU_SUPPORTS_SSSE3)
  endif()

  ##
  ## AVX
  ##
  #From https://gist.github.com/UnaNancyOwen/263c243ae1e05a2f9d0e
  check_cxx_source_compiles("
        #include <immintrin.h>
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
        }" _HAVE_AVX)
  if(_HAVE_AVX)
    add_compile_definitions(CPU_SUPPORTS_AVX)
  endif()


  ##
  ## AVX2
  ##
  #From https://gist.github.com/UnaNancyOwen/263c243ae1e05a2f9d0e
  check_cxx_source_compiles("
        #include <immintrin.h>
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
        }" _HAVE_AVX2)
  if(_HAVE_AVX2)
    add_compile_definitions(CPU_SUPPORTS_AVX2)
  endif()

  ##
  ## AVX512
  ##
  check_cxx_source_compiles("
  #include <immintrin.h>
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
  }" _HAVE_AVX512)
  if(_HAVE_AVX512)
    add_compile_definitions(CPU_SUPPORTS_AVX412)
  endif()

  ##
  ## CLMUL
  ##
  check_cxx_source_compiles("
  #include <immintrin.h>
  int main()
  {
    auto a = _mm_clmulepi64_si128(_mm_cvtsi64_si128(1), _mm_cvtsi64_si128(2), 0);
    return 0;
  }" _HAVE_CLMUL)
  if(_HAVE_CLMUL)
    add_compile_definitions(CPU_SUPPORTS_CLMUL)
  endif()

endmacro()
