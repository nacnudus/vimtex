" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#text_obj#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_text_obj_enabled', 1)
endfunction

" }}}1
function! vimtex#text_obj#init_script() " {{{1
endfunction

" }}}1
function! vimtex#text_obj#init_buffer() " {{{1
  if !g:vimtex_text_obj_enabled | return | endif

  " Utility maps to avoid conflict with "normal" command
  nnoremap <buffer> <sid>(v) v
  nnoremap <buffer> <sid>(V) V

  " Paragraphs
  xnoremap <silent><buffer>  <sid>(vimtex-ip) :<c-u>call vimtex#text_obj#paragraphs(1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-ap) :<c-u>call vimtex#text_obj#paragraphs()<cr>
  xmap     <silent><buffer> <plug>(vimtex-ip) <sid>(vimtex-ip)
  xmap     <silent><buffer> <plug>(vimtex-ap) <sid>(vimtex-ap)
  onoremap <silent><buffer> <plug>(vimtex-ip) :execute "normal \<sid>(V)\<sid>(vimtex-ip)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-ap) :execute "normal \<sid>(V)\<sid>(vimtex-ap)"<cr>

  " Environments
  xnoremap <silent><buffer>  <sid>(vimtex-ie) :<c-u>call vimtex#text_obj#environments(1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-ae) :<c-u>call vimtex#text_obj#environments()<cr>
  xmap     <silent><buffer> <plug>(vimtex-ie) <sid>(vimtex-ie)
  xmap     <silent><buffer> <plug>(vimtex-ae) <sid>(vimtex-ae)
  onoremap <silent><buffer> <plug>(vimtex-ie) :execute "normal \<sid>(v)\<sid>(vimtex-ie)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-ae) :execute "normal \<sid>(v)\<sid>(vimtex-ae)"<cr>

  " Inline math
  xnoremap <silent><buffer>  <sid>(vimtex-i$) :<c-u>call vimtex#text_obj#inline_math(1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-a$) :<c-u>call vimtex#text_obj#inline_math()<cr>
  xmap     <silent><buffer> <plug>(vimtex-i$) <sid>(vimtex-i$)
  xmap     <silent><buffer> <plug>(vimtex-a$) <sid>(vimtex-a$)
  onoremap <silent><buffer> <plug>(vimtex-i$) :execute "normal \<sid>(v)\<sid>(vimtex-i$)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-a$) :execute "normal \<sid>(v)\<sid>(vimtex-a$)"<cr>

  " Delimiters
  xnoremap <silent><buffer>  <sid>(vimtex-id) :<c-u>call vimtex#text_obj#delimiters(1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-ad) :<c-u>call vimtex#text_obj#delimiters()<cr>
  xmap     <silent><buffer> <plug>(vimtex-id) <sid>(vimtex-id)
  xmap     <silent><buffer> <plug>(vimtex-ad) <sid>(vimtex-ad)
  onoremap <silent><buffer> <plug>(vimtex-id) :execute "normal \<sid>(v)\<sid>(vimtex-id)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-ad) :execute "normal \<sid>(v)\<sid>(vimtex-ad)"<cr>
endfunction

" }}}1

function! vimtex#text_obj#delimiters(...) " {{{1
  let inner = a:0 > 0

  let [d1, l1, c1, d2, l2, c2] = vimtex#delim#get_surrounding()

  if inner
    let c1 += len(d1)
    if c1 != len(getline(l1))
      let l1 += 1
      let c1 = 1
    endif
  endif

  if inner
    let c2 -= 1
    if c2 < 1
      let l2 -= 1
      let c2 = len(getline(l2))
    endif
  else
    let c2 += len(d2) - 1
  endif

  if l1 < l2 || (l1 == l2 && c1 < c2)
    call cursor(l1,c1)
    if visualmode() ==# 'V'
      normal! V
    else
      normal! v
    endif
    call cursor(l2,c2)
  endif
endfunction

" }}}1
function! vimtex#text_obj#environments(...) " {{{1
  let inner = a:0 > 0

  let [env, lnum, cnum, lnum2, cnum2] = vimtex#util#get_env(1)
  call cursor(lnum, cnum)
  if inner
    if env =~# '^\'
      call search('\\.\_\s*\S', 'eW')
    else
      call search('}\(\_\s*\(\[\_[^]]*\]\|{\_\S\{-}}\)\)\?\_\s*\S', 'eW')
    endif
  endif
  if visualmode() ==# 'V'
    normal! V
  else
    normal! v
  endif
  call cursor(lnum2, cnum2)
  if inner
    call search('\S\_\s*', 'bW')
  else
    if env =~# '^\'
      normal! l
    else
      call search('}', 'eW')
    endif
  endif
endfunction

" }}}1
function! vimtex#text_obj#inline_math(...) " {{{1
  let l:inner = a:0 > 0

  let l:flags = 'bW'
  let l:dollar = 0
  let l:dollar_pat = '\\\@<!\$'

  if vimtex#util#in_syntax('texMathZoneX')
    let l:dollar = 1
    let l:pattern = [l:dollar_pat, l:dollar_pat]
    let l:flags .= 'c'
  elseif getline('.')[col('.') - 1] ==# '$'
    let l:dollar = 1
    let l:pattern = [l:dollar_pat, l:dollar_pat]
  elseif vimtex#util#in_syntax('texMathZoneV')
    let l:pattern = ['\\(', '\\)']
    let l:flags .= 'c'
  elseif getline('.')[col('.') - 2:col('.') - 1] ==# '\)'
    let l:pattern = ['\\(', '\\)']
  else
    return
  endif

  call s:search_and_skip_comments(l:pattern[0], l:flags)

  if l:inner
    execute 'normal! ' l:dollar ? 'l' : 'll'
  endif

  execute 'normal! ' visualmode() ==# 'V' ? 'V' : 'v'

  call s:search_and_skip_comments(l:pattern[1], 'W')

  if l:inner
    normal! h
  elseif !l:dollar
    normal! l
  endif
endfunction
" }}}1
function! vimtex#text_obj#paragraphs(...) " {{{1
  let inner = a:0 > 0

  " Define selection
  normal! 0j
  call vimtex#motion#next_paragraph(1,0)
  normal! jV
  call vimtex#motion#next_paragraph(0,0)

  " Go back one line for inner objects
  if inner
    normal! k
  endif
endfunction

" }}}1

function! s:search_and_skip_comments(pat, ...) " {{{1
  " Usage: s:search_and_skip_comments(pat, [flags, stopline])
  let flags             = a:0 >= 1 ? a:1 : ''
  let stopline  = a:0 >= 2 ? a:2 : 0
  let saved_pos = getpos('.')

  " search once
  let ret = search(a:pat, flags, stopline)

  if ret
    " do not match at current position if inside comment
    let flags = substitute(flags, 'c', '', 'g')

    " keep searching while in comment
    while vimtex#util#in_comment()
      let ret = search(a:pat, flags, stopline)
      if !ret
        break
      endif
    endwhile
  endif

  if !ret
    " if no match found, restore position
    call setpos('.', saved_pos)
  endif

  return ret
endfunction
" }}}1

" vim: fdm=marker sw=2
