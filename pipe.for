*
*     program an
      implicit real*8 (a-h,o-z)
      include 'mpif.h'
      parameter (Imax=129, Jmax=129, Kmax=129)
      character*12 fncp,fndat
      character*256 comment
      dimension
     > ub(0:Imax,0:Jmax,0:Kmax)
     >,vb(0:Imax,0:Jmax,0:Kmax)
     >,wb(0:Imax,0:Jmax,0:Kmax)
     >,bx(0:Imax,0:Jmax,0:Kmax)
     >,br(0:Imax,0:Jmax,0:Kmax)
     >,bt(0:Imax,0:Jmax,0:Kmax)
     >,u(0:Imax,0:Jmax,0:Kmax)
     >,v(0:Imax,0:Jmax,0:Kmax)
     >,w(0:Imax,0:Jmax,0:Kmax)
     >,u1(0:Imax,0:Jmax,0:Kmax)
     >,v1(0:Imax,0:Jmax,0:Kmax)
     >,w1(0:Imax,0:Jmax,0:Kmax)
     >,u2(0:Imax,0:Jmax,0:Kmax)
     >,v2(0:Imax,0:Jmax,0:Kmax)
     >,w2(0:Imax,0:Jmax,0:Kmax)
     >,u3(0:Imax,0:Jmax,0:Kmax)
     >,v3(0:Imax,0:Jmax,0:Kmax)
     >,w3(0:Imax,0:Jmax,0:Kmax)
     >,ox(0:Imax,0:Jmax,0:Kmax)
     >,or(0:Imax,0:Jmax,0:Kmax)
     >,ot(0:Imax,0:Jmax,0:Kmax)
     >,p(0:Imax,0:Jmax,0:Kmax)
     >,q(0:Imax,0:Jmax,0:Kmax)
     >,buf(2*Imax*Jmax*Kmax)
      common
     >/dim/Xmax,epsr,nsym
     >/dimx/hx,Im,Imm,lx
     >/dimr/rt(0:128),rt1(0:128),yt(129),yt1(129),hr,Jm
     >/dimt/ht,Km,lt
     >/Re/Re
     >/proc/Np,Npm
     >/cf/cf
*
      integer status(MPI_STATUS_SIZE)
      call MPI_INIT(ier)
      call MPI_COMM_SIZE(MPI_COMM_WORLD,Npm,ier)
      call MPI_COMM_RANK(MPI_COMM_WORLD,Np,ier)
 
      if(Np.eq.0)then
        open(5,file='pipe.car')
        read(5,*) tol
        read(5,*) nprt
        read(5,*) nwrt
        read(5,*) tmax
        read(5,*) dtmax
        read(5,*) fnbcp
        read(5,*) fncp
        read(5,*) fndat
        istop=0
        open(9,file=fncp,form='unformatted',status='old',err=111)
      end if
222   call MPI_BCAST(istop,1,MPI_INTEGER,0,MPI_COMM_WORLD,ier)
      if(istop.ne.0) goto 333
      if(Np.eq.0) read(9)t,dt,Dp,Re,Xmax,epsr,lx,Jm,lt,nsym
*
      call MPI_BCAST(tol,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ier)
      call MPI_BCAST(nprt,1,MPI_INTEGER,0,MPI_COMM_WORLD,ier)
      call MPI_BCAST(nwrt,1,MPI_INTEGER,0,MPI_COMM_WORLD,ier)
      call MPI_BCAST(tmax,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ier)
      call MPI_BCAST(dtmax,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ier)
      call MPI_BCAST(cf,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ier)
*
      call MPI_BCAST(t,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ier)
      call MPI_BCAST(dt,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ier)
      call MPI_BCAST(Re,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ier)
      call MPI_BCAST(Xmax,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ier)
      call MPI_BCAST(epsr,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ier)
      call MPI_BCAST(lx,1,MPI_INTEGER,0,MPI_COMM_WORLD,ier)
      call MPI_BCAST(Jm,1,MPI_INTEGER,0,MPI_COMM_WORLD,ier)
      call MPI_BCAST(lt,1,MPI_INTEGER,0,MPI_COMM_WORLD,ier)
      call MPI_BCAST(nsym,1,MPI_INTEGER,0,MPI_COMM_WORLD,ier)
*
      call com
      if(Np.eq.0) then      
      write(*,*)' ***************************************************'
      write(*,*)' *        Number of processors =',Npm,'          *'
      write(*,200) t,dt,Dp,Re,Xmax,epsr,Imm,Jm,Km,nsym
      write(*,*)' ***************************************************'
200   format('    t=',1pe10.3,' dt=',e9.2,' Dp=',e9.2,/,
     >'    Re=',e9.2,/,
     >'    Xmax=',e9.2,/,
     >'    epsr=',e9.2,' Im=',i4,' Jm=',i4,' Km=',i4,' Nsym=',i3)
*
      if(Im.gt.Imax-1.or.Im*Npm.gt.2048) then
        write(*,*)'  Im=',Im,'  is greater than   Imax-1=',Imax-1
        goto 333
      end if
      if(Jm.gt.Jmax-1.or.Jm.gt.128) then
        write(*,*)'  Jm=',Jm,'  is greater than   Jmax-1=',Jmax-1
        goto 333
      end if
      if(Km.gt.Kmax-1.or.Km.gt.256) then
        write(*,*)'  Km=',Km,'  is greater than   Kmax=',Kmax
        goto 333
      end if
      end if
*
      do k=1,Km
        do j=1,Jm
          if(Np.eq.0) then
            read(9)(buf(i),i=1,Imm)
            read(9)(buf(i+Imm),i=1,Imm)
            read(9)(buf(i+2*Imm),i=1,Imm)
            do i=1,Im
              u(i,j,k)=buf(i)
              v(i,j,k)=buf(i+Imm)
              w(i,j,k)=buf(i+2*Imm)
            end do
            do n=1,Npm-1
              call MPI_SEND(buf(n*Im+1),Im,MPI_DOUBLE_PRECISION
     >                     ,n,1,MPI_COMM_WORLD,ier)              
              call MPI_SEND(buf(n*Im+1+Imm),Im,MPI_DOUBLE_PRECISION
     >                     ,n,2,MPI_COMM_WORLD,ier)              
              call MPI_SEND(buf(n*Im+1+2*Imm),Im,MPI_DOUBLE_PRECISION
     >                     ,n,3,MPI_COMM_WORLD,ier)             
            end do
          else
            call MPI_RECV(u(1,j,k),Im,MPI_DOUBLE_PRECISION,0,1
     >                   ,MPI_COMM_WORLD,status,ier)
            call MPI_RECV(v(1,j,k),Im,MPI_DOUBLE_PRECISION,0,2
     >                   ,MPI_COMM_WORLD,status,ier)
            call MPI_RECV(w(1,j,k),Im,MPI_DOUBLE_PRECISION,0,3
     >                   ,MPI_COMM_WORLD,status,ier)
          end if
          call MPI_BARRIER(MPI_COMM_WORLD,ier)
        end do
      end do
      if(Np.eq.0) then
        close(9)
        istop=0
        open(9,file=fncp,form='unformatted',status='old',err=11)
      end if
22    call MPI_BCAST(istop,1,MPI_INTEGER,0,MPI_COMM_WORLD,ier)
      if(istop.ne.0) goto 333
      if(Np.eq.0) read(9)cf,Xmax1,epsr1,lx1,Jm1,lt1,nsym1
*
      if(Xmax.ne.Xmax1) goto 555
      if(epsr.ne.epsr1) goto 555
      if(lx.ne.lx1) goto 555
      if(Jm.ne.Jm1) goto 555
      if(lt.ne.lt1) goto 555
      if(nsym.ne.nsym1) goto 555
*
      do k=1,Km
        do j=1,Jm
          if(Np.eq.0) then
            read(9)(buf(i),i=1,Imm)
            read(9)(buf(i+Imm),i=1,Imm)
            read(9)(buf(i+2*Imm),i=1,Imm)
            do i=1,Im
              ub(i,j,k)=buf(i)
              vb(i,j,k)=buf(i+Imm)
              wb(i,j,k)=buf(i+2*Imm)
            end do
            do n=1,Npm-1
              call MPI_SEND(buf(n*Im+1),Im,MPI_DOUBLE_PRECISION
     >                     ,n,1,MPI_COMM_WORLD,ier)              
              call MPI_SEND(buf(n*Im+1+Imm),Im,MPI_DOUBLE_PRECISION
     >                     ,n,2,MPI_COMM_WORLD,ier)              
              call MPI_SEND(buf(n*Im+1+2*Imm),Im,MPI_DOUBLE_PRECISION
     >                     ,n,3,MPI_COMM_WORLD,ier)             
            end do
          else
            call MPI_RECV(ub(1,j,k),Im,MPI_DOUBLE_PRECISION,0,1
     >                   ,MPI_COMM_WORLD,status,ier)
            call MPI_RECV(vb(1,j,k),Im,MPI_DOUBLE_PRECISION,0,2
     >                   ,MPI_COMM_WORLD,status,ier)
            call MPI_RECV(wb(1,j,k),Im,MPI_DOUBLE_PRECISION,0,3
     >                   ,MPI_COMM_WORLD,status,ier)
          end if
          call MPI_BARRIER(MPI_COMM_WORLD,ier)
        end do
      end do
      if(Np.eq.0) then
        read(9,err=77) comment
        write(*,*) fnbcp,' comment: ',comment
77      close(9)
      end if
      dt=min(dt,dtmax)
*
      call base_rp(t,ub,vb,wb,bx,br,bt,buf,Imax,Jmax)
      call rp(t,ub,vb,wb,bx,br,bt,u,v,w,u1,v1,w1,ox,or,ot,buf,Imax,Jmax)
      p(0,0,1)=0.d0
      call pres(u1,v1,w1,p,buf,Imax,Jmax)
*
      if(Np.eq.0) open(8,file=fndat,access='append')
*
      call servis(t,u,v,w,ox,or,ot,p,0,Imax,Jmax)
      call prt(t,dt,u,v,w,p,Imax,Jmax)
      lprt=0
      lwrt=0
      if(Np.eq.0) time0=MPI_WTIME()
10    continue
      call step(t,dt,tol,ub,vb,wb,bx,br,bt
     > ,u,v,w,u1,v1,w1,u2,v2,w2
     > ,u3,v3,w3,ox,or,ot,p,q
     > ,buf,Imax,Jmax)
      lprt=lprt+1
      lwrt=lwrt+1
      dt=min(dt,dtmax)
      call servis(t,u,v,w,ox,or,ot,p,0,Imax,Jmax)
      if(lprt.ge.nprt.or.t.ge.tmax) then
        lprt=0
        call servis(t,u,v,w,ox,or,ot,p,1,Imax,Jmax)
        call prt(t,dt,u,v,w,p,Imax,Jmax)
      end if
      if(lwrt.ge.nwrt.or.t+0.01*dt.ge.tmax) then
        lwrt=0
        call servis(t,u,v,w,ox,or,ot,p,2,Imax,Jmax)
        if(Np.eq.0) then
          time1=MPI_WTIME()
        open(9,file=fncp,form='unformatted')
        Dp=p(0,0,0)
        write(9)t,dt,Dp,Re,Xmax,epsr,lx,Jm,lt,nsym
        end if
        do k=1,Km
          do j=1,Jm
            if(Np.eq.0) then
              do i=1,Im
                buf(i)=u(i,j,k)
                buf(i+Imm)=v(i,j,k)
                buf(i+2*Imm)=w(i,j,k)
              end do
              do n=1,Npm-1
                call MPI_RECV(buf(n*Im+1),Im,MPI_DOUBLE_PRECISION
     >                     ,n,1,MPI_COMM_WORLD,status,ier)
                call MPI_RECV(buf(n*Im+1+Imm),Im,MPI_DOUBLE_PRECISION
     >                     ,n,2,MPI_COMM_WORLD,status,ier)
                call MPI_RECV(buf(n*Im+1+2*Imm),Im,MPI_DOUBLE_PRECISION
     >                     ,n,3,MPI_COMM_WORLD,status,ier)
              end do
              write(9)(buf(i),i=1,Imm)
              write(9)(buf(i+Imm),i=1,Imm)
              write(9)(buf(i+2*Imm),i=1,Imm)
            else
              call MPI_SEND(u(1,j,k),Im,MPI_DOUBLE_PRECISION,0,1
     >                     ,MPI_COMM_WORLD,ier)              
              call MPI_SEND(v(1,j,k),Im,MPI_DOUBLE_PRECISION,0,2
     >                     ,MPI_COMM_WORLD,ier)              
              call MPI_SEND(w(1,j,k),Im,MPI_DOUBLE_PRECISION,0,3
     >                     ,MPI_COMM_WORLD,ier)   
            end if
            call MPI_BARRIER(MPI_COMM_WORLD,ier)
          end do
        end do
        if(Np.eq.0) then
          close(9)
          close(8)
          write(*,*)'*************************************************'
          write(*,*)'*               Control Point                   *'
          write(*,*)'*      Npm=',Npm,'  time=',time1-time0,'         *'
          write(*,*)'*************************************************'
          open(8,file=fndat,access='append')
          time0=MPI_WTIME()
        end if
      end if 
      if(t+0.01*dt.lt.tmax) goto 10
*
333   continue
      call MPI_FINALIZE(ier)
      stop
111   write(*,*)'  cp file ',fncp,' was not found'
      istop=1
      goto 222
11    write(*,*)'  base file ',fnbcp,' was not found'
      istop=1
      goto 22
555   write(*,*) 'grid is differ:',Xmax,Xmax1,epsr,epsr1,
     > lx,lx1,Jm,Jm1,lt,lt1,nsym,nsym1
      stop
      end
