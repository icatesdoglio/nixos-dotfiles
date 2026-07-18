" Dadbod adapter for Databricks SQL Warehouse via dbsqlcli.
"
" URL format:
"   databricks://hostname/catalog.schema?http_path=/sql/1.0/warehouses/ID
"
" Credentials are passed via DBSQLCLI_ACCESS_TOKEN (set by databricks_refresh()
" in init.lua) — no token ever appears in a stored URL.

function! s:parse(url) abort
  let host      = matchstr(a:url, '://\zs[^/?#]*')
  let path      = matchstr(a:url, '://[^/]*/\zs[^?#]*')
  let http_path = matchstr(a:url, '[?&]http_path=\zs[^&#]*')
  return {'host': host, 'path': path, 'http_path': http_path}
endfunction

function! s:cmd(url) abort
  let p = s:parse(a:url)
  let args = ['dbsqlcli', '--hostname', p.host, '--http-path', p.http_path]
  if !empty(p.path)
    call add(args, p.path)
  endif
  return args
endfunction

function! db#adapter#databricks#canonicalize(url) abort
  return a:url
endfunction

function! db#adapter#databricks#interactive(url) abort
  return s:cmd(a:url)
endfunction

function! db#adapter#databricks#filter(url) abort
  return s:cmd(a:url) + ['-e', '/dev/stdin', '--table-format', 'ascii']
endfunction

function! db#adapter#databricks#input(url, in) abort
  return s:cmd(a:url) + ['-e', a:in, '--table-format', 'ascii']
endfunction

function! db#adapter#databricks#tables(url) abort
  " SHOW TABLES returns: namespace, tableName, isTemporary
  " Qualify with the catalog.schema from the URL so we don't land in hive_metastore.
  let p = s:parse(a:url)
  let show = empty(p.path) ? 'SHOW TABLES' : 'SHOW TABLES IN ' . p.path
  let out = db#systemlist(s:cmd(a:url) + ['-e', show, '--table-format', 'csv'])
  " Skip header row; extract second CSV column (tableName)
  return filter(
        \ map(out[1:], {_, l -> matchstr(l, '^[^,]*,\zs[^,]*\ze,')}),
        \ {_, v -> !empty(v)})
endfunction
