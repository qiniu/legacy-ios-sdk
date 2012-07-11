/* /////////////////////////////////////////////////////////////////////////
 * File:        b64/urlsafe_b64.h
 *
 * Purpose:     Header file for the b64 library
 *
 * Created:     18th October 2004
 * Updated:     18th November 2009
 *
 * Thanks:      To Adam McLaurin, for ideas regarding the b64_decode2() and
 *              b64_encode2().
 *
 * Home:        http://synesis.com.au/software/
 *
 * Copyright (c) 2004-2009, Matthew Wilson and Synesis Software
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * - Neither the name(s) of Matthew Wilson and Synesis Software nor the names of
 *   any contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * ////////////////////////////////////////////////////////////////////// */


/** \file b64/b64.h
 *
 * \brief [C/C++] Header file for the b64 library.
 */

#ifndef B64_INCL_URLSAFE_B64_H_B64
#define B64_INCL_URLSAFE_B64_H_B64

#ifndef B64_INCL_B64_H_B64
#include "b64.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

/** Encodes a block of binary data into Base-64
 *
 * \param src Pointer to the block to be encoded. May not be NULL, except when
 *   \c dest is NULL, in which case it is ignored.
 * \param srcSize Length of block to be encoded
 * \param dest Pointer to the buffer into which the result is to be written. May
 *   be NULL, in which case the function returns the required length
 * \param destLen Length of the buffer into which the result is to be written. Must
 *   be at least as large as that indicated by the return value from
 *   \link b64::b64_encode b64_encode(NULL, srcSize, NULL, 0)\endlink.
 *
 * \return 0 if the size of the buffer was insufficient, or the length of the
 * converted buffer was longer than \c destLen
 *
 * \note The function returns the required length if \c dest is NULL
 *
 * \note The function returns the required length if \c dest is NULL. The returned size
 *   might be larger than the actual required size, but will never be smaller.
 *
 * \note Threading: The function is fully re-entrant.
 *
 * \see b64::encode()
 */
size_t urlsafe_b64_encode(
    void const* src
,   size_t      srcSize
,   b64_char_t* dest
,   size_t      destLen
);

/** Encodes a block of binary data into Base-64
 *
 * \param src Pointer to the block to be encoded. May not be NULL, except when
 *   \c dest is NULL, in which case it is ignored.
 * \param srcSize Length of block to be encoded
 * \param dest Pointer to the buffer into which the result is to be written. May
 *   be NULL, in which case the function returns the required length
 * \param destLen Length of the buffer into which the result is to be written. Must
 *   be at least as large as that indicated by the return value from
 *   \link b64::b64_encode2 b64_encode2(NULL, srcSize, NULL, 0, flags, lineLen, rc)\endlink.
 * \param flags A combination of the B64_FLAGS enumeration, that moderate the
 *   behaviour of the function
 * \param lineLen If the flags parameter contains B64_F_LINE_LEN_USE_PARAM, then
 *   this parameter represents the length of the lines into which the encoded form is split,
 *   with a hard line break ('\\r\\n'). If this value is 0, then the line is not
 *   split. If it is <0, then the RFC-1113 recommended line length of 64 is used
 * \param rc The return code representing the status of the operation. May be NULL.
 *
 * \return 0 if the size of the buffer was insufficient, or the length of the
 *   converted buffer was longer than \c destLen
 *
 * \note The function returns the required length if \c dest is NULL. The returned size
 *   might be larger than the actual required size, but will never be smaller.
 *
 * \note Threading: The function is fully re-entrant.
 *
 * \see b64::encode()
 */
size_t urlsafe_b64_encode2(
    void const* src
,   size_t      srcSize
,   b64_char_t* dest
,   size_t      destLen
,   unsigned    flags
,   int         lineLen /* = 0 */
,   B64_RC*     rc     /* = NULL */
);

/** Decodes a sequence of Base-64 into a block of binary data
 *
 * \param src Pointer to the Base-64 block to be decoded. May not be NULL, except when
 *   \c dest is NULL, in which case it is ignored. If \c dest is NULL, and \c src is
 *   <b>not</b> NULL, then the returned value is calculated exactly, otherwise a value
 *   is returned that is guaranteed to be large enough to hold the decoded block.
 *
 * \param srcLen Length of block to be encoded. Must be an integral of 4, the Base-64
 *   encoding quantum, otherwise the Base-64 block is assumed to be invalid
 * \param dest Pointer to the buffer into which the result is to be written. May
 *   be NULL, in which case the function returns the required length
 * \param destSize Length of the buffer into which the result is to be written. Must
 *   be at least as large as that indicated by the return value from
 *   \c b64_decode(src, srcSize, NULL, 0), even in the case where the encoded form
 *   contains a number of characters that will be ignored, resulting in a lower total
 *   length of converted form.
 *
 * \return 0 if the size of the buffer was insufficient, or the length of the
 *   converted buffer was longer than \c destSize
 *
 * \note The function returns the required length if \c dest is NULL. The returned size
 *   might be larger than the actual required size, but will never be smaller.
 *
 * \note \anchor anchor__4_characters The behaviour of both
 * \link b64::b64_encode2 b64_encode2()\endlink
 * and
 * \link b64::b64_decode2 b64_decode2()\endlink
 * are undefined if the line length is not a multiple of 4.
 *
 * \note Threading: The function is fully re-entrant.
 *
 * \see b64::decode()
 */
size_t urlsafe_b64_decode(
    b64_char_t const*   src
,   size_t              srcLen
,   void*               dest
,   size_t              destSize
);

/** Decodes a sequence of Base-64 into a block of binary data
 *
 * \param src Pointer to the Base-64 block to be decoded. May not be NULL, except when
 * \c dest is NULL, in which case it is ignored. If \c dest is NULL, and \c src is
 * <b>not</b> NULL, then the returned value is calculated exactly, otherwise a value
 * is returned that is guaranteed to be large enough to hold the decoded block.
 *
 * \param srcLen Length of block to be encoded. Must be an integral of 4, the Base-64
 *   encoding quantum, otherwise the Base-64 block is assumed to be invalid
 * \param dest Pointer to the buffer into which the result is to be written. May
 *   be NULL, in which case the function returns the required length
 * \param destSize Length of the buffer into which the result is to be written. Must
 *   be at least as large as that indicated by the return value from
 *   \c b64_decode(src, srcSize, NULL, 0), even in the case where the encoded form
 *   contains a number of characters that will be ignored, resulting in a lower total
 *   length of converted form.
 * \param flags A combination of the B64_FLAGS enumeration, that moderate the
 *   behaviour of the function.
 * \param rc The return code representing the status of the operation. May be NULL.
 * \param badChar If the flags parameter does not contain B64_F_STOP_ON_NOTHING, this
 *   parameter specifies the address of a pointer that will be set to point to any
 *   character in the sequence that stops the parsing, as dictated by the flags
 *   parameter. May be NULL.
 *
 * \return 0 if the size of the buffer was insufficient, or the length of the
 * converted buffer was longer than \c destSize, or a bad character stopped parsing.
 *
 * \note The function returns the required length if \c dest is NULL. The returned size
 *   might be larger than the actual required size, but will never be smaller.
 *
 * \note The behaviour of both
 * \link b64::b64_encode2 b64_encode2()\endlink
 * and
 * \link b64::b64_decode2 b64_decode2()\endlink
 * are undefined if the line length is not a multiple of 4.
 *
 * \note Threading: The function is fully re-entrant.
 *
 * \see b64::decode()
 */
size_t urlsafe_b64_decode2(
    b64_char_t const*   src
,   size_t              srcLen
,   void*               dest
,   size_t              destSize
,   unsigned            flags
,   b64_char_t const**  badChar /* = NULL */
,   B64_RC*             rc      /* = NULL */
);

#ifdef __cplusplus
} /* extern "C" */
#endif /* __cplusplus */

#endif /* B64_INCL_URLSAFE_B64_H_B64 */
