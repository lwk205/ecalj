Cgetarg...info...           structure ['clsprm', 'ctrl', 'sctrl']
Cgetarg...info...           structure ['clsprm', 'ham', 'sham']
Cgetarg...info...           structure ['clsprm', 'array', 'sarray']
Cgetarg...info...           structure ['clsprm', 'pot', 'spot']
Cgetarg...info...           structure ['clsprm', 'lat', 'slat']
Cgetarg...info...           structure ['clsprm', 'spec', 'sspec']
Cgetarg...info...           structure ['clsprm', 'bz', 'sbz']
Cgetarg...info...           use_to_add ['clsprm', 'm_struc_def']
      subroutine clsprm(mode,sctrl,sarray,sham,spot,sspec,slat,sbz,
     .  sstr,sstrn)
       
       use m_struc_def  !Cgetarg

C- Allocate memory for, and try to read, class-related data
C ----------------------------------------------------------------------
Ci    mode :1s digit
Ci         : 1 allocates ASA arrays (see spot,sham,sarray)
Ci         : 2 allocates TBE arrays:  oifrlx
Ci   sctrl :struct for program flow parameters; see routine uctrl
Ci     Elts read: nbas nclass nl nspin nspec loptc nmap
Ci     Stored:    *
Ci     Passed to: lgors ioqpp aiocls clsprp
Ci   sarray:structure containing offsets to various arrays
Ci     Elts read: nclasp oics oipc oclabl opos
Ci     Stored:    ogroup ormax ohave oifrlx ozos
Ci     Passed to: aiocls clsprp
Ci   sham  :struct for parameters defining hamiltonian; see routine uham
Ci     Elts read: *
Ci     Stored:    osop oivso
Ci     Passed to: aiocls clsprp
Ci   spot  :struct for information about the potential; see routine upot
Ci     Elts read: ovrmax orhrmx opnu oqnu opp oves
Ci     Stored:    opnu oqnu oqc oqt oves ovdif ovrmax orhrmx opp orhos
Ci                osop ogrrme ovintr opmpol oqpp
Ci     Passed to: ioqpp aiocls clsprp
Ci   sspec :struct for species-specific information; see routine uspec
Ci     Elts read: rmt idmod z lmxa
Ci     Stored:    *
Ci     Passed to: aiocls clsprp
Ci   slat  :struct for lattice information; see routine ulat
Ci     Elts read: plat
Ci     Stored:    *
Ci     Passed to: aiocls clsprp
Ci   sbz   :struct for the Brillouin Zone; see routine ubz
Ci     Elts read: ndos
Ci     Stored:    *
Ci     Passed to: clsprp
Ci
Ci   sstr  :struct for parameters for screened strux; see routine ustr
Ci     Elts read: n map
Ci     Stored:    *
Ci     Passed to: *
Ci   sstrn :struct for global strings
Ci     Elts read: map
Ci     Stored:    *
Ci     Passed to: clsprp
Cu Updates
Cu   08 Nov 07 (J. Xu) LDA+U implementation; qpp is complex
Cu   30 Sep 04 Reads/writes relativistic ppar's
Cu   02 Apr 04 SO array redimensioned; make and pack pot->nrhos
Cu   18 Mar 03 Allocate space for relativistic potential parameters
Cu   07 Feb 03 SO array redimensioned
Cu   19 Feb 02 entry clsprp copies class data to doubly padded layers
Cu   28 Apr 98 allocate space for radial matrix elements of grad
C ----------------------------------------------------------------------
C     implicit none
      integer mode
      character*(*) sstrn
Cgetarg       double precision sctrl(1),sarray(1),sham(1),spot(1),sspec(1),
Cgetarg      .  slat(1),sbz(1),sstr(1)
       type(s_ctrl)::sctrl
       type(s_array)::sarray
       type(s_ham)::sham
       type(s_pot)::spot
       type(s_spec)::sspec(*)
       type(s_lat)::slat
       type(s_bz)::sbz
       type(s_str)::sstr

C Local variables
      logical lgors,cmdopt
      character*80 strn,clabl*8
      integer obxc,oinitc,opnu,oqnu,oqc,oqt,oves,ovdif,orhrmx,ovrmax,
     .  orhos,osop,ogroup,ovintr,opp,opprel,oifrlx,oivso,oipc,oclabl,
     .  opos,oics,ozos,ormax,opmpol,oqpp,ogrrme,n0
      parameter (n0=10)
      integer nbas,nclass,nspec,nl,nsp,nlspc,igets,nclasp,i1,i2,nmap,ic,
     .  is,ib,iclbsj,idmod(n0),iprint,lmx,nclspp,nqpp,lnsph,isw,neula,
     .  nbf,nrhos,nlibu
C     integer nmto,oppn
      double precision plat(9),z,xx,dval
C ... Heap
      integer w(1)
      common /w/ w

      integer,allocatable:: ics(:)

Cgetarg...info...           integer :: nbas , integer(8) :: sctrl%nbas 1
Cgetarg...info...           integer :: nclass , integer(8) :: sctrl%nclass 1
Cgetarg...info...           integer :: nl , integer(8) :: sctrl%nl 1
Cgetarg...info...           integer :: nsp , integer(8) :: sctrl%nspin 1
Cgetarg...info...           integer :: nspec , integer(8) :: sctrl%nspec 1
Cgetarg       call upack('ctrl nbas nclass nl nspin nspec',sctrl,nbas,nclass,nl,
Cgetarg      .  nsp,nspec)

       nbas=sctrl%nbas
       nclass=sctrl%nclass
       nl=sctrl%nl
       nsp=sctrl%nspin
       nspec=sctrl%nspec

Cgetarg...info...           integer :: nlibu , integer(8) :: sham%nlibu 1
Cgetarg       call upack('ham nlibu',sham,nlibu,0,0,0,0)
       
       nlibu=sham%nlibu

Cgetarg...info...           integer :: nclasp , integer(8) :: sarray%nclasp 1
Cgetarg       call upack1('array nclasp',sarray,nclasp)
       
       nclasp=sarray%nclasp

      nclspp = max(2*nclasp-nclass,nspec)
      nlspc = nl*nsp*max(nclspp,nspec)

C ... Allocate ASA arrays
      if (mod(mode,10) .eq. 1) then
        call defdr(opnu,-nlspc)
        call defdr(oqnu,-3*nlspc)
        call defdr(opp,-6*nlspc)
        call defdr(opprel,-32*nl*nl*max(nclspp,nspec))
        call defdr(oqc,-nclasp)
        call defdr(oqt,-nclasp)
        call defi (oinitc,-nclasp)
        call defi (ogroup,-2*nclasp)
        call defdr(oves,-nclspp)
        call defdr(ovdif,-nclspp)
        call defdr(orhrmx,-nclspp)
        call defdr(ovrmax,-2*nclspp)
C       call defdr(oqnu,-3*nlspc)
Cgetarg...info...           integer :: oics , integer(8) :: sarray%oics 1
Cgetarg         call upack1('array oics',sarray,oics)
         
         oics=sarray%oics


cccccccccccccccccccccccccccccccccccccccccccc
c         print *,'bbbbbb 111',nclspp
cccccccccccccccccccccccccccccccccccccccccccc

c takao sp2cls is replaced.
c        call sp2cls('spec rmt',sspec,w(oics),1,1,nclspp,ormax)
         allocate( ics(nclspp) )
         call icopy(nclspp,w(oics),1,ics,1)
         call defdr(ormax,nclspp)
         call dcopy(nclspp,sspec(ics(1:nclspp))%rmt,1,w(ormax),1)


cccccccccccccccccccccccccccccccccccccccccccccccccc
c      do ic=1,nclspp
c        print *, 'bbbbbb 222' ,ic, dval(w(ormax),ic)
c      enddo
c      stop 'xxxxxxxxxxxxxxxxxxx'
cccccccccccccccccccccccccccccccccccccccccccccccccc


Cgetarg...info...           integer :: ogroup , integer(8) :: sarray%ogroup 1
Cgetarg...info...           integer :: ormax , integer(8) :: sarray%ormax 1
Cgetarg...info...           integer :: oinitc , integer(8) :: sarray%ohave 1
Cgetarg         call pack5('array ogroup ormax ohave',sarray,ogroup,ormax,
Cgetarg      .    oinitc,0,0)
         
         sarray%ogroup=ogroup 
         sarray%ormax=ormax 
         sarray%ohave=oinitc 

Cgetarg...info...           integer :: opnu , integer(8) :: spot%opnu 1
Cgetarg...info...           integer :: oqnu , integer(8) :: spot%oqnu 1
Cgetarg...info...           integer :: oqc , integer(8) :: spot%oqc 1
Cgetarg...info...           integer :: oqt , integer(8) :: spot%oqt 1
Cgetarg         call pack5('pot opnu oqnu oqc oqt',spot,opnu,oqnu,oqc,oqt,0)
         
         spot%opnu=opnu 
         spot%oqnu=oqnu 
         spot%oqc=oqc 
         spot%oqt=oqt 

Cgetarg...info...           integer :: oves , integer(8) :: spot%oves 1
Cgetarg...info...           integer :: ovdif , integer(8) :: spot%ovdif 1
Cgetarg...info...           integer :: ovrmax , integer(8) :: spot%ovrmax 1
Cgetarg...info...           integer :: orhrmx , integer(8) :: spot%orhrmx 1
Cgetarg...info...           integer :: opp , integer(8) :: spot%opp 1
Cgetarg         call pack5('pot oves ovdif ovrmax orhrmx opp',spot,oves,ovdif,
Cgetarg      .    ovrmax,orhrmx,opp)
         
         spot%oves=oves 
         spot%ovdif=ovdif 
         spot%ovrmax=ovrmax 
         spot%orhrmx=orhrmx 
         spot%opp=opp 

C       Even in collinear case, bxc might be written to
        call defdr(obxc,-3*nclasp)
Cgetarg...info...           integer :: opprel , integer(8) :: spot%opprel 1
Cgetarg...info...           integer :: obxc , integer(8) :: spot%obxc 1
Cgetarg         call pack5('pot opprel obxc nrhos',spot,opprel,obxc,0,0,0)
         
         spot%opprel=opprel 
         spot%obxc=obxc 
         spot%nrhos=0 

Cgetarg         if (lgors('ctrl lncol,-1',sctrl)) then
c
c takao Kino's bug--> his replied that iand(-1,i)=i 
c         if ( iand(-1,int(sctrl%lncol)) .ne.0 ) then 

         if ( sctrl%lncol /=0 ) then 
Cgetarg...info...           integer :: neula , integer(8) :: sham%neula 1
Cgetarg...info...           integer :: nbf , integer(8) :: sham%nbf 1
Cgetarg           call upack2('ham neula nbf',sham,neula,nbf)
          neula=sham%neula
          nbf=sham%nbf
          nrhos = max(nl,neula,nbf)
          call rlse(obxc)
          call defdr(orhos,2*3*4*nrhos*nclasp)
          call defdr(osop,-nlspc*nsp*9)
          call defdr(obxc,-3*nclasp)
Cgetarg...info...           integer :: nrhos , integer(8) :: spot%nrhos 1
Cgetarg...info...           integer :: orhos , integer(8) :: spot%orhos 1
Cgetarg...info...           integer :: obxc , integer(8) :: spot%obxc 1
Cgetarg...info...           integer :: osop , integer(8) :: spot%osop 1
Cgetarg           call pack5('pot nrhos orhos obxc osop',spot,
Cgetarg      .      nrhos,orhos,obxc,osop,0)
          spot%nrhos=nrhos 
          spot%orhos=orhos 
          spot%obxc=obxc 
          spot%osop=osop 
        endif

        ogrrme = 0
Cgetarg         if (igets('ctrl loptc',sctrl) .gt. 0)
Cgetarg      .    call defrr(ogrrme,-16*nl*nsp*nclasp)
         if ( int(sctrl%loptc) .gt. 0 ) call defrr ( ogrrme , -16 * nl 
     .   * nsp * nclasp ) 

Cgetarg...info...           integer :: ogrrme , integer(8) :: spot%ogrrme 1
Cgetarg         call pack1('pot ogrrme',spot,ogrrme)
         
         spot%ogrrme=ogrrme 

Cgetarg         if (lgors('ctrl lsx,3',sctrl) .or.
Cgetarg      .      lgors('ctrl lscr,-1',sctrl)) then
         if ( iand(3,int(sctrl%lsx)) .ne.0 .or. iand(-1,int(sctrl%lscr)) .ne.0 
     .   ) then 

          call defdr(ovintr,-nclasp*(nl*nsp)**2)
Cgetarg...info...           integer :: ovintr , integer(8) :: spot%ovintr 1
Cgetarg           call pack1('pot ovintr',spot,ovintr)
           
           spot%ovintr=ovintr 

        endif
Cgetarg         lnsph = isw(lgors('ctrl lasa,32',sctrl))
c         lnsph = isw ( iand(32,int(sctrl%lasa)) .ne.0 ) 
ctakao remove asa
         lnsph = isw ( .false.)

C   ... Allocate memory for, attempt to read qpp from file
        if (lnsph .ne. 0 .or. nlibu .ne. 0) then
          call defrr(opmpol,-(2*nl-1)*nl**2*3*nsp*nclasp)
          i1 = nl**2
          nqpp = (i1*(i1+1))/2
          call defrr(oqpp,2*nqpp*4*nsp*nbas)
          call dvset(w(oqpp),1,1,-1d0)
Cgetarg...info...           integer :: opmpol , integer(8) :: spot%opmpol 1
Cgetarg...info...           integer :: oqpp , integer(8) :: spot%oqpp 1
Cgetarg           call pack2('pot opmpol oqpp',spot,opmpol,oqpp)
           spot%opmpol=opmpol 
           spot%oqpp=oqpp 
          call ioqpp(.false.,sctrl,spot)
        endif

Cgetarg...info...           real(8) :: plat(9) , real(8) :: slat%plat 9
Cgetarg         call upack1('lat plat',slat,plat)
         
C$$$         i_copy_size=size(slat%plat) 
C$$$         call dcopy(i_copy_size,slat%plat,1,plat,1) 


C$$$C   --- Create maps ---
C$$$Cgetarg         nmap = igets('ctrl nmap',sctrl)
C$$$         nmap = int(sctrl%nmap) 



C$$$cccccccccccccccccc
C$$$         print *,' xxxxxx 222 nmap=',nmap
C$$$cccccccccccccccccc
 


C$$$        if (nmap .gt. 0) then
C$$$          call upacks('strn map',i1,i2)
C$$$Cgetarg...info...           integer :: oipc , integer(8) :: sarray%oipc 1
C$$$Cgetarg...info...           integer :: oclabl , integer(8) :: sarray%oclabl 1
C$$$Cgetarg...info...           integer :: opos , integer(8) :: sarray%opos 1
C$$$Cgetarg           call upack('array oipc oclabl opos',sarray,oipc,oclabl,opos,0,
C$$$Cgetarg      .      0)
           
C$$$           oipc=sarray%oipc
C$$$           oclabl=sarray%oclabl
C$$$           opos=sarray%opos

C$$$Cgetarg...info...           integer :: ovrmax , integer(8) :: spot%ovrmax 1
C$$$Cgetarg...info...           integer :: orhrmx , integer(8) :: spot%orhrmx 1
C$$$Cgetarg           call upack('pot ovrmax orhrmx',spot,ovrmax,orhrmx,0,0,0)
           
C$$$           ovrmax=spot%ovrmax
C$$$           orhrmx=spot%orhrmx

C$$$Cgetarg...info...           integer :: opnu , integer(8) :: spot%opnu 1
C$$$Cgetarg...info...           integer :: oqnu , integer(8) :: spot%oqnu 1
C$$$Cgetarg...info...           integer :: opp , integer(8) :: spot%opp 1
C$$$Cgetarg...info...           integer :: oves , integer(8) :: spot%oves 1
C$$$Cgetarg           call upack('pot opnu oqnu opp oves',spot,opnu,oqnu,opp,oves,0)
           
C$$$           opnu=spot%opnu
C$$$           oqnu=spot%oqnu
C$$$           opp=spot%opp
C$$$           oves=spot%oves

C$$$          do  10  ic = 1, nclass
C$$$            xx = dval(w(oclabl),ic)
C$$$            call r8tos8(xx,clabl)
C$$$            is = w(oics+ic-1)
C$$$            ib = iclbsj(ic,w(oipc),-nbas,1)
C$$$Cgetarg...info...           integer :: idmod(n0) , integer(8) :: sspec%idmod 10
C$$$Cgetarg             call upack('spec idmod',sspec,is,idmod,0,0,0)
             
C$$$             i_copy_size=size(sspec(is)%idmod) 
C$$$             call i8icopy(i_copy_size,sspec(is)%idmod,1,idmod,1) 

C$$$            if (ib .lt. 0) then
C$$$              if (iprint() .ge. 20) print *,
C$$$     .          'CLSPRM: no basis corresponding to class ' //clabl
C$$$              goto 10
C$$$            endif
C$$$Cgetarg...info...           real(8) :: z , real(8) :: sspec%z 1
C$$$Cgetarg...info...           integer :: lmx , integer(8) :: sspec%lmxa 1
C$$$Cgetarg             call upack('spec z lmxa',sspec,is,z,lmx,0,0)
             
C$$$             z=sspec(is)%z
C$$$             lmx=sspec(is)%lmxa

C$$$            call wrmap(sstrn(i1:i2),nmap,clabl,ic,ib,z,plat,w(opos))
C$$$Cgetarg             call mapq(clabl,ic-1,nl,nsp,lmx,idmod,w(opnu),w(oqnu),
C$$$Cgetarg      .        w(opp),w(opprel),w(orhrmx),w(ovrmax),
C$$$Cgetarg      .        lgors('ctrl lves,1',sctrl),w(oves),w(oinitc))
C$$$             call mapq ( clabl , ic-1 , nl , nsp , lmx , idmod , w ( opnu 
C$$$     .       ) , w ( oqnu ) , w ( opp ) , w ( opprel ) , w ( orhrmx ) , w 
C$$$     .       ( ovrmax ) , iand(1,int(sctrl%lves)) .ne.0 , w ( oves ) , w ( 
C$$$     .       oinitc ) ) 

C$$$   10     continue

C$$$          if (cmdopt('-spin1',6,0,strn))
C$$$     .      call spinav(0,nclass,nl,nsp,w(opnu),w(oqnu))
C$$$          if (cmdopt('-map0',5,0,strn)) then
C$$$            call aiocls(.true.,0,sarray,sctrl,sham,spot,sspec,slat,1,
C$$$     .        nclass)
C$$$            call rx0('mapped moments written')
C$$$          endif
C$$$        endif
      endif

C$$$C --- Allocate tbe arrays ---
C$$$      if (mod(mode,10) .eq. 2) then
C$$$        call defi(oifrlx,-4*nbas)
C$$$Cgetarg...info...           integer :: oifrlx , integer(8) :: sarray%oifrlx 1
C$$$Cgetarg         call pack5('array oifrlx',sarray,oifrlx,0,0,0,0)
         
C$$$         sarray%oifrlx=oifrlx 

C$$$Cgetarg         if (lgors('ctrl lncol,-1',sctrl)) then
C$$$         if ( iand(-1,int(sctrl%lncol)) .ne.0 ) then 

C$$$          call rx('clsprm: is this needed?')
C$$$          call defdr(osop,-nlspc*nsp*9)
C$$$          call defi (oivso,-nclasp*nl)
C$$$CKi          call pack5('ham osop oivso',sham,osop,oivso,0,0,0)
C$$$Cgetarg...info...           integer :: osop , integer(8) :: spot%osop 1
C$$$Cgetarg...info...           integer :: oivso , integer(8) :: spot%oivso 1
C$$$Cgetarg           call pack5('pot osop oivso',spot,osop,oivso,0,0,0)
           
C$$$           spot%osop=osop 
C$$$           spot%oivso=oivso 

C$$$        endif
C$$$      endif

C$$$Cgetarg       if (lgors('ctrl lstonr,-1',sctrl)) then
C$$$      if ( iand(-1,int(sctrl%lstonr(1))) .ne.0 ) then 

C$$$C        call defdr(oammx,-nclasp)
C$$$C        call defdr(ostni,-nclasp)
C$$$Cgetarg         call defdr(ozos,igets('bz ndos',sbz)*nl*nsp*nclasp)
C$$$         call defdr ( ozos , int(sbz%ndos) * nl * nsp * nclasp ) 

C$$$Cgetarg...info...           integer :: ozos , integer(8) :: sarray%ozos 1
C$$$Cgetarg         call pack5('array ozos',sarray,ozos,0,0,0,0)
         
C$$$         sarray%ozos=ozos 

C$$$      endif

C --- Misc variables ---
C      oips = igets('array oips',sarray)
C      nla = 0
C      do  20  ib = 1, nbas
C        is = w(oips+ib-1)
C        lmx = igetss('spec lmxa',is,sspec)
C        nla = nla + (lmx+1)**2
C   20 continue
C      call pack1('ctrl nla',sctrl,nla)

C     call shstru('array',sarray,0,0)
C     stop

      return

      entry clsprp(mode,sctrl,sarray,sham,spot,sspec,slat,sbz,
     .  sstr,sstrn)
C- Copy class data to doubly padded case

Cgetarg...info...           integer :: nclass , integer(8) :: sctrl%nclass 1
Cgetarg...info...           integer :: nl , integer(8) :: sctrl%nl 1
Cgetarg...info...           integer :: nsp , integer(8) :: sctrl%nspin 1
Cgetarg...info...           integer :: nspec , integer(8) :: sctrl%nspec 1
Cgetarg       call upack('ctrl nclass nl nspin nspec',sctrl,nclass,nl,nsp,nspec,
Cgetarg      .  0)
       
       nclass=sctrl%nclass
       nl=sctrl%nl
       nsp=sctrl%nspin
       nspec=sctrl%nspec

Cgetarg...info...           integer :: nclasp , integer(8) :: sarray%nclasp 1
Cgetarg       call upack1('array nclasp',sarray,nclasp)
       
       nclasp=sarray%nclasp

      if (nclasp .eq. nclass) return
      nclspp = max(2*nclasp-nclass,nspec)
C ... Allocate ASA arrays
      if (mod(mode,10) .eq. 1) then

        i1 = nclasp-nclass
Cgetarg...info...           integer :: opnu , integer(8) :: spot%opnu 1
Cgetarg...info...           integer :: oqnu , integer(8) :: spot%oqnu 1
Cgetarg         call upack('pot opnu oqnu',spot,opnu,oqnu,0,0,0)
         
         opnu=spot%opnu
         oqnu=spot%oqnu

        call dpscop(w(opnu),w(opnu),nl*nsp*i1,
     .    nl*nsp*nclass+1,nl*nsp*nclasp+1,1d0)
        call dpscop(w(oqnu),w(oqnu),3*nl*nsp*i1,
     .    3*nl*nsp*nclass+1,3*nl*nsp*nclasp+1,1d0)

Cgetarg...info...           integer :: oves , integer(8) :: spot%oves 1
Cgetarg...info...           integer :: ovdif , integer(8) :: spot%ovdif 1
Cgetarg...info...           integer :: ovrmax , integer(8) :: spot%ovrmax 1
Cgetarg...info...           integer :: orhrmx , integer(8) :: spot%orhrmx 1
Cgetarg         call upack('pot oves ovdif ovrmax orhrmx',spot,oves,ovdif,
Cgetarg      .    ovrmax,orhrmx,0)
         
         oves=spot%oves
         ovdif=spot%ovdif
         ovrmax=spot%ovrmax
         orhrmx=spot%orhrmx

        call dpscop(w(oves),w(oves),i1,nclass+1,nclasp+1,1d0)
        call dpscop(w(ovdif),w(ovdif),i1,nclass+1,nclasp+1,1d0)
        call dpscop(w(ovrmax),w(ovrmax),i1,nclass+1,nclasp+1,1d0)
        call dpscop(w(orhrmx),w(orhrmx),i1,nclass+1,nclasp+1,1d0)

      else
        call rxi('clsprp: bad mode',mode)
      endif

Cgetarg       end
       end subroutine clsprm 

      subroutine mapq(clabl,ic,nl,nsp,lmx,idmod,pnu,qnu,pp,pprel,
     .  rhrmx,vrmax,swmad,ves,initc)

C- Maps moments and pp's from MAP
C ----------------------------------------------------------------------
Ci Inputs:
Co Outputs:
Co   pnu,qnu,pp
Co   initc is updated to reflect changed status
Cr Remarks
Cr   Map has syntax
Cr     name.ext or path/name.ext (one file)
Cr     nfiles: c1 c2 ... cn name1 name1 ... namen (multiple files)
Cr   The 10's digit of c* is interpreted as a switch, to swap
Cr     the up and down spins
Cr   Note: '$' for path is translated into string LIBPTH, below
Cr         '.' uses value of current data
Cr   idmod,rhrmx,vrmax,ves set by 1st mapped file
C ----------------------------------------------------------------------
C     implicit none
C Passed parameters
      character*8 clabl
      integer ic,nl,nsp,lmx,idmod(nl),initc(0:1)
      double precision pnu(nl,nsp,0:1),qnu(3,nl,nsp,0:1),ves(0:1),
     .  pp(6,nl,nsp,0:1),pprel(4,nl,2*nl,2,2,ic),rhrmx(0:1),vrmax(2,0:1)
      logical swmad
C Local variables
      integer a2vec,idwk(6),fext,fextg,fopna,fpath,i,i1mach,lrel,nglob,
     .  ia,ia2,iend,ifi,imap,ip,iterm,ix(10),j,nmap,ipr,initx(2)
      logical scat,a2bin,aiomom,aiopar,last,map2me
      double precision fcof(20),pwk(6*2),qwk(3*6*2),ppwk(6*6*2),
     .  pprwk(32*36*2),rhwk,pout(6*2),qout(3*6*2),ppout(6*6*2),
     .  vrwk(2),pprout(32*36*2),veswk,cof,scof
      character*1 s(0:71),ch(2),chp(4),ss*72,fnam*40,alabl*8
      equivalence (s,ss)
      character*13 LIBPTH
#if unix
      data LIBPTH /'/usr/lmto/lib'/
#endif
      data ch /' ','.'/, chp /'$','~','/','.'/


      call getpr(ipr)
      lrel = nglob('lrel')

C --- Open file, exit if no map ---
      ifi = fopna(clabl,30,0)
      if (.not. scat(ifi,'MAP:',':',.true.)) then
        call fclose(ifi)
        return
      endif

C --- Zero out accumulated moms, pp's ---
      initx(1) = 1
      initx(2) = 1
      call dpzero(pwk,  6*2)
      call dpzero(qwk, 3*6*2)
      call dpzero(ppwk,6*6*2)
      call dpzero(pprwk,32*36*2)
      call dpzero(pout, nl*nsp)
      call dpzero(qout, nl*nsp*3)
      call dpzero(ppout,nl*nsp*6)
      call dpzero(pprout,32*36*2)
      rhwk = 0
      veswk = 0
      vrwk(1) = 0
      vrwk(2) = 0
      scof = 0


C --- Parse the file map and admix coefficients ---
      read(ifi,10) s
   10 format(72a1)
      call fclose(ifi)
      ia = 0
      call skipbl(ss,len(ss),ia)
      call skpblb(ss,len(ss),i)
      if (ipr .ge. 30) print 11, clabl, ss(1:i+1)
   11 format(' MAPQ: mapping class ',a4,' as ',a)
      ia2 = ia
      fcof(1) = 1
      if (a2bin(ss,nmap,2,0,':',ia,len(ss))) then
        if (a2vec(ss,len(ss),ia,4,' ',1,2,nmap,ix,fcof) .ne. nmap)
     .    call fexit(-1,1,' Exit -1 mapq, class ' // clabl //
     .   'syntax error seeking %i coffs in map '//ss(1:ia)//' ...',nmap)
      else
        nmap = 1
        ia = ia2
      endif

C --- Loop over all mapping files ---
      do  5  imap = 1, nmap

C ---   Extract file names: full name in s(ia:iend) ---
        call skipbl(s,72,ia)
        iend = ia
        call chrpos(s,' ',72,iend)
        map2me = iend .eq. ia+1 .and. s(ia) .eq. '.'

C ---   Case map is '.': mapped data is current data ---
        if (map2me) then
          if (mod(initc(ic),2) .eq. 1) then
            call dcopy(nl*nsp,pnu(1,1,ic),1,pwk,1)
            call dcopy(3*nl*nsp,qnu(1,1,1,ic),1,qwk,1)
          else
            if (ipr.ge.20) print *, 'mapq: file missing moments'
            initx(1) = 0
          endif
          if (mod(initc(ic)/2,2) .eq. 1) then
            call dcopy(6*nl*nsp,pp(1,1,1,ic),1,ppwk,1)
            call dcopy(32*nl*nl,pprel(1,1,1,1,1,ic),1,pprwk,1)
          else
            if (ipr.ge.20) print *, 'mapq: file missing ppars'
            initx(2) = 0
          endif
          do  62  i = 1, nl
   62     idwk(i)   = idmod(i)
          vrwk(1)   = vrmax(1,ic)
          vrwk(nsp) = vrmax(nsp,ic)
          rhwk      = rhrmx(ic)
          veswk     = ves(ic)
C --- Case map to another file : extract path name ---
        else
C ...     Path name ...
          fnam = ' '
          ia2 = ia
          i = ia
          call chrps2(s,chp,4,iend,ia2,iterm)
          goto (21,25,25,24), iterm
          goto 27
   21     fnam = LIBPTH
          ia = ia+1
          goto 25
   24     if (ia .ne. ia2) goto 27
C ...     Extract path name, looping until last '/' found
   25     continue
          ip = i
          call chrpos(s,'/',iend,i)
          i = i+1
C print *, i, ip, iend, ss(ia+1:i), ' ', ss(ia+1:ip)
          if (i .lt. iend) goto 25
          i = 0
          call strcat(fnam,32,' ',ss(ia+1:ip),ip-ia,' ',i)
          if (iterm .eq. 2) call rxx(ia.ne.ia2,'mapq: bad path name')
          i = fpath(fnam)
          ia = ip

C --- Open file with local name, ext; then restore them ---
   27     ia2 = ia
          call chrps2(s,ch,2,iend,ia2,iterm)
C  print *, ia, ia2, iend, iterm, ss(ia:ia2), ' .. ', ss(ia2:iend)
          i = fextg(fnam)
          if (iterm .eq. 2) i = fext(ss(ia2+1:iend))
C  print *, 'Opening file ',ss(ia:ia2),', coff=',sngl(fcof(imap))
          ifi = fopna(ss(ia+1:ia2),31,1)
          i = fext(fnam(1:20))
          i = fpath(' ')

C --- Read in moments to wk ---
          alabl = clabl
          rewind ifi
          if (aiomom(alabl,pwk,qwk,idwk,nl,lmx,nsp,rhwk,vrwk,ifi)) then
          else
            initx(1) = 0
            if (ipr .ge. 20) print *,
     .        'mapq: mapped file '//ss(ia+1:ia2)//' missing moments'
          endif

          if (aiopar(alabl,lrel,ppwk,pprwk,veswk,nl,lmx,nsp,ifi)) then
          else
            initx(2) = 0
            if (ipr .ge. 20) print *,
     .        'mapq: mapped file '//ss(ia+1:ia2)//' missing ppars'
          endif
          call fclose(ifi)
        endif

C --- Now wk arrays hold current mapped data ---
        if (imap .eq. 1) then
          do  64  i = 1, nl
   64     idmod(i) = idwk(i)
          vrmax(1,ic) = vrwk(1)
          vrmax(nsp,ic) = vrwk(nsp)
          if (dabs(fcof(1)) .ge. 10) then
            vrmax(1,ic) = vrwk(nsp)
            vrmax(nsp,ic) = vrwk(1)
          endif
          rhrmx(ic) = rhwk
          if (.not. swmad) ves(ic)   = veswk
        endif
C ...   Swap up and down spins
        cof = dsign(dmod(dabs(fcof(imap)),10d0),fcof(imap))
        scof = scof + cof
        if (dabs(fcof(imap)) .ge. 10 .and. nsp .eq. 2) then
          call daxpy(nl,cof,pwk(1+nl),1,pout,1)
          call daxpy(nl,cof,pwk,1,pout(1+nl),1)
          call daxpy(3*nl,cof,qwk(1+3*nl),1,qout,1)
          call daxpy(3*nl,cof,qwk,1,qout(1+3*nl),1)
          call daxpy(6*nl,cof,ppwk(1+6*nl),1,ppout,1)
          call daxpy(6*nl,cof,ppwk,1,ppout(1+6*nl),1)
          if (lrel .eq. 2) call rx('mapq: spin swap not implemented')
        else
          call daxpy(nl*nsp,cof,pwk,1,pout,1)
          call daxpy(3*nl*nsp,cof,qwk,1,qout,1)
          call daxpy(6*nl*nsp,cof,ppwk,1,ppout,1)
          call daxpy(32*nl**2,cof,pprwk,1,pprout,1)
        endif

        ia = iend+1
    5 continue

C --- Copy mapped data back to p's, q's and ppar's ---
      call dcopy(nl*nsp,pout,1,pnu(1,1,ic),1)
      call dcopy(nl*nsp*3,qout,1,qnu(1,1,1,ic),1)
      call dcopy(nl*nsp*6,ppout,1,pp(1,1,1,ic),1)
      call dcopy(nl*nsp*6,pprout,1,pprel(1,1,1,1,1,ic),1)
      initc(ic) = 4*(initc(ic)/4) + initx(1) + 2*initx(2)

C --- Printout ---
      cof = 0
      do  90  i = 1, nsp
      vrwk(i) = 0
      do  90  j = 1, nl
   90 vrwk(i) = vrwk(i) + qnu(1,j,i,ic)
      ss =
     . ' mapq: sum of coffs= %d   valence charge= %1;6d   moment= %1;6d'
      if (ipr .ge. 30 .and. nsp .eq. 1)
     .  call awrit2(ss(1:47),' ',80,i1mach(2),scof,vrwk)
      if (ipr .ge. 30 .and. nsp .eq. 2) call awrit3(ss(1:63),
     .  ' ',80,i1mach(2),scof,vrwk(1)+vrwk(2),vrwk(2)-vrwk(1))
      if (ipr .le. 40) return
      if (mod(initc(ic),2) .eq. 1)
     .  last = aiomom(clabl,pnu(1,1,ic),qnu(1,1,1,ic),
     .  idmod(1),nl,lmx,nsp,rhrmx(ic),vrmax(1,ic),-i1mach(2))
      if (mod(initc(ic)/2,2) .eq. 1)
     .  last = aiopar(clabl,lrel,pp(1,1,1,ic),pprel(1,1,1,1,1,ic),
     .                ves(ic),nl,lmx,nsp,-i1mach(2))


Cgetarg       end
       end subroutine mapq 

      subroutine wrmap(maprul,nmap,clabl,ic,ib,z,planvc,bas)

C- Appends map to atom file according to maprul
C ----------------------------------------------------------------------
Ci Inputs:
Ci   maprul,ic, ific:file handle
Ci   ib:     any basis atom corresponding to class
Co Outputs:
Co   Map appended to atom files
Cr Remarks
Cr   Each file is tested against each map until a match is found.
Cr   If no match found, nothing is done.
Cr   Map syntax:  key:  map-pattern
Cr   where mapnam is wild-card expanded by the shell;
Cr   there is a match when the present atom file is one of the files.
Cr   When there is a match, a map is appended to the current file,
Cr   using the map pattern.  All occurences of strings '\h' and '\t'
Cr   in the map pattern are substituted by the current class name and
Cr   extension, respectively.  A backslash followed by an expresssion
Cr   in parenthesis, eg '\{job}', is evaluated as an expression and
Cr   whose value is inserted as an ascii string.  Example: atom
Cr   name=A, extension=x, variable job=31.  the map pattern
C    \h\t:g\{job+1}z is translated into A.x:g32z .
C    Example of a map:
C    MAP     F  [ac]:     \h.1:g\{job}
C               b:         c.2:g\{job}
C               *:         a.3:g\{job}
C    If extension=x and job=3, this maps classes a and c into
C    a.1:g3 and c.1:g3, class b into b.2:g3 and all other classes
C    into file a.3:g3
C    Argument list and convention differ slightly from FP version.
C    For each class, class-specific variables ic,ib,x,y,z,n are loaded
C    into the variables table before coefficients are parsed.
C ----------------------------------------------------------------------
C     implicit none
C Passed Parameters
      integer ib,ic,ific,nmap,reclen
      double precision planvc(3,3),bas(3,1),z
      parameter (reclen=120)
      character maprul(1)*(reclen),clabl*8
C Local Variables
      integer imap,ich,ln,iout,i,ich0,fextg,iprint,ncof,i2,j,fopna,
     .  ix(10),ival,iv0,a2vec,i1mach
      double precision fcof(10),ddot,xx
      logical foundm,a2bin,scat
      character tstr*40,chx(2),ext*40,hch*2,tch*2,pch*2,sch
      character*1 s(0:71),ss*72,fmt*40
      equivalence (s,ss)

      data chx /':',' '/
c CRAY is removed. takao mar2010
c #if CRAY 
c       data hch /'\h'/ tch /'\t'/ sch /'\'/ pch /'\{'/
c #else
      data hch /'\\h'/ tch /'\\t'/ sch /'\\'/ pch /'\\{'/
c #endif

C --- Until a key matches atom file, do ---
      if (iprint() .ge. 30) print *
      do  20  imap = 1, nmap
        if (maprul(imap) .eq. ' ') goto 20
        ich = 0
        call skipbl(maprul(imap),reclen,ich)
        ich0 = ich
C   ... Quick check to avoid system call
        if (maprul(imap)(ich+1:ich+3) .eq. '*: ') then
          ich = ich+2
          foundm = .true.
          goto 22
        endif
        call chrps2(maprul(imap),chx,2,72,ich,i)
        call rxx(i.ne.1,'WRMAP: bad key in map:'//maprul(imap)(1:20))
        tstr = ' '
        call strcop(tstr,clabl,8,' ',i)
        if (tstr(i:i) .eq. ' ') i = i-1
        j = fextg(ext)
        call strcop(tstr(i+1:40),ext,40,' ',j)
        call locase(tstr)
C       call chrpos(tstr,' ',40,ich)
        ss = 'ls '// maprul(imap)(ich0+1:ich) // ext(1:j)
     .    // '|grep -s '// tstr
C       print *, ss
        call fsystm(ss,j)
        foundm = j .eq. 0
        ich = ich+1
C ...   Regather, with foundm and ich set
   22   continue
        if (iprint() .gt. 40) print *, 'WRMAP: sought map for class ',
     .    clabl,' in key ', maprul(imap)(ich0+1:ich),
     .    '  ... found=',foundm
        if (.not. foundm) goto 20
        call skipbl(maprul(imap),reclen,ich)
        if (ich .ge. reclen) then
          if (iprint() .gt. 40) print *, 'WRMAP: empty map'
          return
        endif

C ---   Map found:  parse coffs and maprul substituting \h,\t,\{ ---
        iout = 0
        ss = ' '
        ich0 = ich
C ...   first look for coffs, calling a2bin to sub
        if (a2bin(maprul(imap),ncof,2,0,':',ich0,reclen)) then
          call skipbl(maprul(imap),reclen,ich0)
          ich = ich0
          write(ss(2:3),'(i1,'':'')') ncof
          fmt = ' '
          write(fmt(1:9),'('':%'',i1,'':1;6d'')') ncof
          iout = 3

          call numsyv(iv0)
          call lodsyv('ic',1,dble(ic),ival)
          call lodsyv('zc',1,z,ival)
          call lodsyv('ib',1,dble(ib),ival)
          call lodsyv('x', 1,bas(1,ib),ival)
          call lodsyv('y', 1,bas(2,ib),ival)
          call lodsyv('z', 1,bas(3,ib),ival)
          xx = ddot(3,bas(1,ib),1,planvc(1,3),1) /
     .         dsqrt(ddot(3,planvc(1,3),1,planvc(1,3),1))
          call lodsyv('n', 1,bas(3,ib),ival)
C         call shosyv(0,0,0,6)
          i2 = a2vec(maprul(imap),reclen,ich,4,',; ',3,3,-10,ix,fcof)
          j = 0
          do  24  i = 1, i2
            if (ix(i) .ne. 2) then
              j = j+1
              fcof(j) = fcof(i)
            endif
   24     continue
          if (j .ne. ncof) then
            call awrit3(' WRMAP map %i:  sought %i coefficients but'//
     .        ' found only %i',' ',72,i1mach(2),imap,ncof,j)
            call rx('Failed to parse map'//maprul(imap)(1:ich)//' ...')
          endif
          call awrit1(fmt(1:9),ss(iout:72),72-iout+1,0,fcof)
          call skpblb(ss,72,iout)
          iout = iout+2
          call clrsyv(iv0)
        endif

   28   continue
        ich0 = ich
        call chrpos(maprul(imap),sch,reclen,ich)
        ln = ich-ich0
        call strcop(s(iout),maprul(imap)(ich0+1:reclen),ln,sch,i)
        iout = iout+i
        if (ich .ge. reclen) goto 30
        if (maprul(imap)(ich+1:ich+2) .eq. hch) then
          call strcat(s(iout),72-iout,' ' ,clabl,8,' ',i)
          iout = iout+i
          ich = ich+2
          if (s(iout-1) .eq. ' ') iout = iout-1
        endif
        if (maprul(imap)(ich+1:ich+2) .eq. tch) then
          i = fextg(tstr)
          call strcat(s(iout),72-iout,' ' ,tstr,20,' ',i)
          iout = iout+i
          ich = ich+2
          if (s(iout-1) .eq. ' ') iout = iout-1
        endif
        if (maprul(imap)(ich+1:ich+2) .eq. pch) then
          ich = ich+2
          if (.not. a2bin(maprul(imap),fcof,4,0,'}',ich,reclen))
     .      call rx('WRMAP: bad expr in map'//maprul(imap)(1:ich))
          call bin2a(' ',0,0,fcof,4,0,72,ss,iout)
        endif
C        if (maprul(imap)(ich+1:ich+1) .eq. sch) then
C          s(iout) = sch
C          ich = ich+1
C          iout = iout+1
C        endif
c       print *, ss
        goto 28
   20 continue
   30 continue

      if (.not. foundm) then
        if (iprint() .ge. 20)
     .    print *, 'WRMAP:  no map found for class ', clabl
        return
      endif

C --- Supersede existing map, or append map to atom file ---
      ific = fopna(clabl,30,0)
      if (.not. scat(ific,'MAP:',':',.true.)) then
        call poseof(ific)
        write(ific,'(''MAP:'')')
      endif
      write(ific,'(a72)') ss
      if (iprint() .ge. 30) print *, 'WRMAP:  wrote map for class ',
     .    clabl,' ', ss
      call fclose(ific)

Cgetarg       end
       end subroutine wrmap 




C================================================================
c take subs/ioqpp.F here
Cgetarg...info...           structure ['ioqpp', 'ctrl', 'sctrl']
Cgetarg...info...           structure ['ioqpp', 'pot', 'spot']
Cgetarg...info...           use_to_add ['ioqpp', 'm_struc_def']
      subroutine ioqpp(lio,sctrl,spot)
       
       use m_struc_def  !Cgetarg

C- File i/o for phi-phi, phi-dot, dot-dot products
C ----------------------------------------------------------------------
Ci Inputs:
Ci   lio: true for write, false for read
Ci          <0 write
Cu Updates
Cu   08 Nov 07 (J. Xu) qpp is complex
C ----------------------------------------------------------------------
C     implicit none
C ... Passed parameters
      logical lio
Cgetarg       double precision sctrl(1),spot(1)
       type(s_ctrl)::sctrl
       type(s_pot)::spot

C ... Heap
      integer w(1)
      common /w/ w
C ... Local parameters
      integer i1,i2,nbas,nl,nsp,igets,ifi,oqpp,fopna,rdm,ipr

      call getpr(ipr)
Cgetarg...info...           integer :: nbas , integer(8) :: sctrl%nbas 1
Cgetarg...info...           integer :: nl , integer(8) :: sctrl%nl 1
Cgetarg...info...           integer :: nsp , integer(8) :: sctrl%nspin 1
Cgetarg       call upack('ctrl nbas nl nspin',sctrl,nbas,nl,nsp,0,0)
       
       nbas=sctrl%nbas
       nl=sctrl%nl
       nsp=sctrl%nspin

      i1 = nl**2*(nl**2+1)
      i2 = 4*nsp*nbas
Cgetarg       oqpp = igets('pot oqpp',spot)
       oqpp = int(spot%oqpp) 

      ifi = fopna('qpp',-1,4+8)

      if (lio) then
        call ywrm(1,'lmasa',1,ifi,' ',w(oqpp),1,i1,i1,i2)
        if (ipr .ge. 30) print *, 'IOQPP:  wrote qpp to disk'
      else
        if (ipr .ge. 30) print *, 'IOQPP:  reading qpp from disk ...'
        call pshpr(0)
        if (rdm(ifi,2,i1*i2,' ',w(oqpp),i1,i2) .lt. 0) then
          if (ipr .ge. 0) print *,'IOQPP:  (warning) failed to qpp file'
          call dvset(w(oqpp),1,1,-1d0)
        endif
        call poppr
      endif

      call fclose(ifi)
Cgetarg       end
       end subroutine ioqpp 


C================================================================
c take subs/spinav.F here
      subroutine spinav(mode,nclass,nl,nsp,pnu,qnu)
C- Averages up+down spin moments + pp's for all classes
C ----------------------------------------------------------------------
Ci Inputs
Ci   mode  :0 average spins
Ci         :1 do not average, but exchange spins
Ci   nclass:number of inequivalent classes
Ci   nl    :(global maximum l) + 1
Ci   nsp   :2 for spin-polarized case, otherwise 1
Ci   pnu   :boundary conditions.  If Dl = log. deriv. at rmax,
Ci          pnu = .5 - atan(Dl)/pi + (princ.quant.number).
Ci   qnu   :energy-weighted moments of the sphere charges
Co Outputs :moments are spin-averaged
Ci   pnu   :spin-averaged (mode=0) or spin-flipped (mode=1)
Ci   qnu   :spin-averaged (mode=0) or spin-flipped (mode=1)
Co   nsp   :set to 1 on output (mode=0)
Cl Local variables
Cl         :
Cr Remarks
Cr   
Cu Updates
Cu   10 Jan 06 Added mode
C ----------------------------------------------------------------------
C     implicit none
      integer mode,nclass,nl,nsp,ic
      double precision pnu(nl,nsp,nclass),qnu(3,nl,nsp,nclass)

      if (nsp .eq. 1) return

      if (mode .gt. 1) then
        call rx('spinav: bad mode')
      elseif (mode .eq. 1) then
        do  ic = 1, nclass
          call dswap(nl,pnu(1,2,ic),1,pnu(1,1,ic),1)
          call dswap(3*nl,qnu(1,1,2,ic),1,qnu(1,1,1,ic),1)
        enddo
        return
      endif

      do  ic = 1, nclass
        call daxpy(nl,1d0,pnu(1,2,ic),1,pnu(1,1,ic),1)
        call dscal(nl,.5d0,pnu(1,1,ic),1)
        call daxpy(3*nl,1d0,qnu(1,1,2,ic),1,qnu(1,1,1,ic),1)
      enddo

      do  ic = 2, nclass
        call dcopy(nl,pnu(1,1,ic),1,pnu(1,ic,1),1)
        call dcopy(3*nl,qnu(1,1,1,ic),1,qnu(1,1,ic,1),1)
      enddo
      nsp = 1
      end

