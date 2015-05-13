*
      subroutine pres(u,v,w,p,Jmax)
      implicit real*8 (a-h,o-z)
      complex*16 u,v,w,p,d,c0,ci,Dp,Ub,su,ssu,aa,bb
      dimension
     > u(0:Jmax,0:*)
     >,v(0:Jmax,0:*)
     >,w(0:Jmax,0:*)
     >,p(0:Jmax,0:*)
     >,a1(2048),a2(2048),aa(2048)
     >,b1(2048),b2(2048),bb(2048)
     >,bp(2048)
      common
     >/dimr/rt(0:128),rt1(0:128),yt(129),yt1(129),hr,Jm
     >/dimt/ht,Km,lt
     >/rlt/rlt(256)
     >/pry/apy(128),bpy(128),cpy(128)
     >/alpha/alpha
*
      c0=(0.d0,0.d0)
      ci=(0.d0,1.d0)
* bc
      do j=1,Jm
        w(j,0)=c0
        w(j,Km)=c0
      end do
      do k=1,Km
        v(Jm,k)=c0
      end do

      do k=1,Km
        do j=1,Jm
          call div(j,k,u,v,w,d,Jmax)
          p(j,k)=d
        end do
      end do
*
*   FFT in tt-direction
      do j=1,Jm
        do k=1,Km
          a1(k)=real(p(j,k))
          a2(k)=aimag(p(j,k))
        end do
        call ftc05d(a1,b1,lt)
        call ftc05d(a2,b2,lt)
        do k=1,Km
          a1(k)=b1(k)*2.0/Km
          a2(k)=b2(k)*2.0/Km
          p(j,k)=a1(k)+ci*a2(k)
        end do
      end do
*
*   Solution in wall-normal coordinate
      do k=1,Km
        do j=1,Jm
          bp(j)=bpy(j)-rlt(k)/yt(j)**2-alpha**2
          aa(j)=p(j,k)
        end do
        bp(1)=bp(1)+apy(1)
        bp(Jm)=bp(Jm)+cpy(Jm)
        Jm1=Jm
        bb(Jm)=c0
        if(alpha.eq.0.d0)
          if(rlt(k).eq.0.d0) Jm1=Jm-1
        call prog3(apy,bp,cpy,aa,bb,Jm1)
        do j=1,Jm
          p(j,k)=bb(j)
        end do
      end do
*
*   Inverse FFT in tt-direction
      do j=1,Jm
        do k=1,Km
          a1(k)=real(p(j,k))
          a2(k)=aimag(p(j,k))
        end do
        call ftc05b(a1,b1,lt)
        call ftc05b(a2,b2,lt)
        do k=1,Km
          p(j,k)=b1(k)+ci*b2(k)
        end do
      end do
*
*  Mean pressure gradient
!  Ub = 0.0 in all cases
      if(alpha.eq.0.d0) then
        ss=0.d0
        su=c0
        do j=1,Jm
          ss=ss+yt(j)*yt1(j)
          ssu=c0
          do k=1,Km
            ssu=ssu+u(j,k)
          end do
          su=su+ssu*yt(j)*yt1(j)
        end do
        Dp=-su/(Km*ss)
        write(*,*) Dp
        do k=1,Km
          do j=1,Jm
            u(j,k)=u(j,k)+Dp
          end do
        end do
      end if
*
      call gradp(u,v,w,p,Jmax)
      return
      end
*
      subroutine gradp(u,v,w,p,Jmax)
      implicit real*8 (a-h,o-z)
      complex*16 u,v,w,p,ci
      dimension
     > u(0:Jmax,0:*)
     >,v(0:Jmax,0:*)
     >,w(0:Jmax,0:*)
     >,p(0:Jmax,0:*)
      common
     >/dimr/rt(0:128),rt1(0:128),yt(129),yt1(129),hr,Jm
     >/dimt/ht,Km,lt
     >/alpha/alpha
      ci=(0.d0,1.d0)
      do k=1,Km
        do j=1,Jm
          u(j,k)=u(j,k)-ci*alpha*p(j,k)
        end do
      end do
*
      do k=1,Km
        do j=1,Jm-1
          v(j,k)=v(j,k)-(p(j+1,k)-p(j,k))/rt1(j)
        end do
      end do
*
      do k=1,Km-1
        do j=1,Jm
          w(j,k)=w(j,k)-(p(j,k+1)-p(j,k))/(yt(j)*ht)
        end do
      end do
      return
      end
*
      subroutine div(j,k,u,v,w,d,Jmax)
      implicit real*8 (a-h,o-z)
      complex*16 u,v,w,d,ci
      dimension
     > u(0:Jmax,0:*)
     >,v(0:Jmax,0:*)
     >,w(0:Jmax,0:*)
      common
     >/dimr/rt(0:128),rt1(0:128),yt(129),yt1(129),hr,Jm
     >/dimt/ht,Km,lt
     >/alpha/alpha
      ci=(0.d0,1.d0)
      d=ci*alpha*u(j,k)
     > +(rt(j)*v(j,k)-rt(j-1)*v(j-1,k))/(yt(j)*yt1(j))
     > +(w(j,k)-w(j,k-1))/(yt(j)*ht)
      return
      end
