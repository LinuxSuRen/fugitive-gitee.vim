function! s:function(name) abort
  return function(substitute(a:name,'^s:',matchstr(expand('<sfile>'), '<SNR>\d\+_'),''))
endfunction

function! s:gitee_url(opts, ...) abort
  if a:0 || type(a:opts) != type({})
    return ''
  endif

  let path = substitute(a:opts.path, '^/', '', '')
  let domain_pattern = 'gitee\.com'
  let domains = exists('g:fugitive_gitee_domains') ? g:fugitive_gitee_domains : []
  for domain in domains
    let domain_pattern .= '\|' . escape(split(domain, '://')[-1], '.')
  endfor
  let repo = matchstr(a:opts.remote,'^\%(https\=://\|git://\|\(ssh://\)\=git@\)\%(.\{-\}@\)\=\zs\('.domain_pattern.'\)[/:].\{-\}\ze\%(\.git\)\=$')
  if repo ==# ''
    return ''
  endif
  if index(domains, 'http://' . matchstr(repo, '^[^:/]*')) >= 0
    let root = 'http://' . substitute(repo,':','/','')
  else
    let root = 'https://' . substitute(repo,':','/','')
  endif
  if path =~# '^\.git/refs/heads/'
    return root . '/commits/' . path[16:-1]
  elseif path =~# '^\.git/refs/tags/'
    return root . '/src/' .path[15:-1]
  elseif path =~# '.git/\%(config$\|hooks\>\)'
    return root . '/admin'
  elseif path =~# '^\.git\>'
    return root
  endif
  if a:opts.commit =~# '^\d\=$'
    let commit = a:opts.repo.rev_parse('HEAD')
  else
    let commit = a:opts.commit
  endif
  if get(a:opts, 'type', '') ==# 'tree' || a:opts.path =~# '/$'
    let url = root
  elseif get(a:opts, 'type', '') ==# 'blob' || a:opts.path =~# '[^/]$'
    let url = root . '/blob/' . commit . '/' . path
    if get(a:opts, 'line1')
      let url .= '#' . fnamemodify(path, ':t') . '-' . a:opts.line1
      if get(a:opts, 'line2')
        let url .= ':' . a:opts.line2
      endif
    endif
  else
    let url = root . '/commits/' . commit
  endif
  return url
endfunction

if !exists('g:fugitive_gitee_handlers')
  let g:fugitive_gitee_handlers = []
endif

call insert(g:fugitive_browse_handlers, s:function('s:gitee_url'))
