scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

function! Weather#Getdata(city)
  let id = Weather#returncity#return(a:city)
  " 都市が対応していない場合，idに0が入る
  if id != 0
    let res = webapi#http#get('http://weather.livedoor.com/forecast/webservice/json/v1?city='.id)
    call s:post(res)
  endif
endfunction

function s:post(res)
  let content = webapi#json#decode(a:res.content)
  let info = []
  if !has("patch-8.1.1453")
    echo "\n"
  endif
  call add(info, "発表日: ".content['publicTime'])
  call add(info, "")
  call add(info, content['title'])
  for weather in content['forecasts']
    call add(info, weather['dateLabel']." ".weather['telop'])
    call add(info, "------------")
  endfor
  call add(info, content['description']['text'])
  echo ""
  echo join(info, "\n")
endfunction

" --- write popupwindow ---"

function! s:popup_menu_update(wid, ctx) abort
  " winbufnr()は現在のウインドウに関連付けられているバッファの番号が返る
  let l:buf = winbufnr(a:wid)
  let l:menu = map(copy(a:ctx.menu), '(v:key == a:ctx.select ? "→" : "  ") .. v:val')
  call setbufline(l:buf, 1, l:menu)
endfunction

function! s:popup_filter(ctx, wid, c) abort
  if a:c ==# 'j'
    let a:ctx.select += a:ctx.select ==# len(a:ctx.menu)-1 ? 0 : 1
    call s:popup_menu_update(s:wid, a:ctx)
  elseif a:c ==# 'k'
    let a:ctx.select -= a:ctx.select ==# 0 ? 0 : 1
    call s:popup_menu_update(s:wid, a:ctx)
  elseif a:c ==# "\n" || a:c ==# "\r" || a:c ==# ' '
    call popup_close(a:wid)
    call Weather#Getdata(a:ctx.menu[a:ctx.select])
  endif
endfunction

function! s:show_popup(menu) abort
  let l:ctx = {'select': 0, 'menu': a:menu}
  let s:wid = popup_create(a:menu, {
        \ 'border': [1,1,1,1],
        \ 'filter': function('s:popup_filter', [l:ctx]),
        \})
  call s:popup_menu_update(s:wid, l:ctx)
endfunction

function! Weather#open() abort
  if has("patch-8.1.1453")
    call s:show_popup([
          \'Sapporo', 
          \'Sendai', 
          \'Tokyo', 
          \'Nagoya', 
          \'Shiga',
          \'Kyoto', 
          \'Osaka', 
          \'Hiroshima',
          \'Hukuoka'
          \])
  else
    let city = input("where?: ")
    call Weather#Getdata(city)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
