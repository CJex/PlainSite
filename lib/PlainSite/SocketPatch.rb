
#coding:utf-8
module PlainSite
  require 'socket'
  module SocketPatch
    class ::TCPSocket
      def peeraddr(*args,&block)
        # Prevent reverse hostname resolve
        args.push :numeric unless args.include? :numeric
        super *args,&block
      end
    end
  end
end

