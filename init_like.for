*
      subroutine init_like(fncp)
      implicit real*8 (a-h,o-z)
      character*24 fncp
      common
     >/dim/Xmax,epsr,nsym
     >/dimx/hx,Im,lx
     >/dimr/rt(0:128),rt1(0:128),yt(0:129),yt1(0:129),hr,Jm
     >/dimt/ht,Km,lt
     >/Re/Re
     >/cf/cf
*
      open(9,file=fncp,form='unformatted',status='old',err=111)
      read(9)t,dt,Dp,Re,Xmax,epsr,lx,Jm,lt,nsym
      close(9)
      call com
      if(Im.gt.2048) write(*,*) 'Im > 2048 (fft,rlx)'
      if(Jm.gt.128) write(*,*) 'Jm > 128 (dimr,..)'
      if(Km.gt.256) write(*,*) 'Km > 256 (rlt)'
      return
111   write(*,*) 'file.scp was not found'
      return
      end
