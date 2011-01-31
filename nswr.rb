require 'sinatra'
require 'dalli'

mc = ::Dalli::Client.new

get '/' do;  redirect "/whatever-#{rand(1000000000)}"; end

get '/:id/*' do
  qstn = params[:splat][0].strip
  redirect "/#{params[:id]}" if qstn.empty?

  nswrs = mc.get(params[:id]) || {}
  nswr = nswrs[qstn]

  unless nswr
    nswrs[qstn] = ''  # FIXME thread unsafe!
    mc.set(params[:id], nswrs)
  end

  content_type :text
  nswr.to_s
end

post '/:id/*' do
  qstn = params[:splat][0].strip
  nswrs = mc.get(params[:id]) || {}
  redirect "/#{params[:id]}" if qstn.empty? || !nswrs[qstn]

  if params[:nswr].to_s.strip.empty?  # FIXME thread unsafe!
    nswrs[qstn] = params[:nswr]
  else
    nswrs.delete(qstn)
  end
  mc.set(params[:id], nswrs)

  redirect "/#{params[:id]}"
end

get '/:id' do
  @nswrs = mc.get(params[:id])

  haml :nswr
end

__END__
@@ nswr
!!!
%html
  %head
    %title&= params[:id]
  %body
    - if @nswrs && !@nswrs.empty?
      - for qstn in @nswrs.keys
        %form(method="post" action="/#{params[:id]}/#{qstn}")
          %pre&= qstn+'?'
          %textarea(rows="3" cols="42" name="nswr")&= @nswrs[qstn]
          %input(type="submit" value="nswr")
    - else
      Tip: the address bar is your friend! Try typing
      = succeed ',' do
        %kbd&= 'nswr.me/' + params[:id] + "/What exactly don't you understand?"
      getting a blank page and then coming back here again.<br />Refresh often.
