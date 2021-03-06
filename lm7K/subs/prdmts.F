      subroutine praldm(ifi,ipr1,ipr2,sharm,nbas,nsp,lmaxu,lldau,sspec,
     .ssite,strn,dmatu)

      use m_struc_def  !Cgetarg
C- Writes out a site density-matrix-like object for all sites
C ----------------------------------------------------------------------
Ci Inputs
Ci   ifi   :if zero, write to stdo, in screen style format
Ci         :else, write to file ifi in high-precision format
Ci   ipr1  :if verbosity ipr>ipr1, print header
Ci   ipr2  :if verbosity ipr>ipr2, print contents of dmats
Ci   sharm :0 if in real harmonics, 1 if in spherical harmonics
Ci   nbas  :size of basis
Ci   nsp   :2 for spin-polarized case, otherwise 1
Ci   lmaxu :dimensioning parameter for U matrix
Ci   lldau :lldau(ib)=0 => no U on this site otherwise
Ci          U on site ib with dmat in dmats(*,lldau(ib))
Ci   sspec :struct for species-specific information; see routine uspec
Ci     Elts read: lmxa idu
Ci     Stored:
Ci     Passed to:
Ci   ssite :struct for site-specific information; see routine usite
Ci     Elts read: spec
Ci     Stored:
Ci     Passed to:
Ci   strn  :string put into header
Ci   dmatu :density matrix for LDA+U
Co Outputs
Co   dmatu is written to file ifi
Cl Local variables
Cl         :
Cr Remarks
Cr
Cu Updates
Cu   27 Jan 06 First created
C ----------------------------------------------------------------------
C     implicit none
C ... Passed parameters
      integer nbas,nsp,lldau(nbas),ifi,lmaxu,ipr1,ipr2,sharm
      type(s_spec)::sspec(*)
      type(s_site)::ssite(*)

      double complex dmatu(-lmaxu:lmaxu,-lmaxu:lmaxu,nsp,*)
      character strn*(*)
C ... Local parameters
      integer iblu,ib,is,igetss,lmxa,idu(4),l

      iblu = 0
      do  ib = 1, nbas
        if (lldau(ib) .ne. 0) then
          is = int(ssite(ib)%spec)


          lmxa=sspec(is)%lmxa
          i_copy_size=size(sspec(is)%idu)
          call icopy(i_copy_size,sspec(is)%idu,1,idu,1)

          do  l = 0, min(lmxa,3)
            if (idu(l+1) .ne. 0) then
              iblu = iblu+1
              call prdmts(ifi,ipr1,ipr2,sharm,strn,ib,l,lmaxu,iblu,dmatu,
     .        nsp,1)
            endif
          enddo
        endif
      enddo
      end subroutine praldm

      subroutine prdmts(ifi,ipr1,ipr2,sharm,strn,ib,l,lmaxu,iblu,dmats,
     .nsp,nspc)

      use m_globalvariables
C- Writes out a site density-matrix-like object for a single l
C ----------------------------------------------------------------------
Ci Inputs
Ci   ifi   :if zero, write to stdo, in screen style format
Ci         :else, write to file ifi in high-precision format
Ci   ipr1  :if verbosity ipr>ipr1, print header
Ci   ipr2  :if verbosity ipr>ipr2, print contents of dmats
Ci   sharm :0 if in real harmonics, 1 if in spherical harmonics
Ci   strn  :string put into header
Ci   ib    :site index (ib=0 suppresses printout)
Ci   l     :dmats defined for l block
Ci   lmaxu :dimensioning parameter for dmats
Ci   iblu  :index to current block
Ci   dmats :site density matrix
Ci   nsp   :2 for spin-polarized case, otherwise 1
Ci   nspc  :2 if spin-up and spin-down channels are coupled; else 1.
Co Outputs
Co  header and dmats are printed to stdo
Cl Local variables
Cl         :
Cr Remarks
Cr
Cu Updates
Cu   09 Nov 05 dmats changed to a complex matrix
Cu   02 Jun 05 First created
C ----------------------------------------------------------------------
C     implicit none
C ... Passed parameters
      integer ifi,ipr1,ipr2,l,ib,lmaxu,nsp,nspc,iblu,sharm
      double precision dmats(2,-lmaxu:lmaxu,-lmaxu:lmaxu,nsp,iblu)
      character strn*(*)
C ... Local parameters
      integer isp,ipr,stdo,nglob,m1,m2,mpipid,nlm
      character strnl*120,strn1*30

      if (nspc .eq. 2) call rx('prdmts not ready for nspc=2')
      if (mpipid(1) .ne. 0) return
      call getpr(ipr)
Changenglob      stdo = nglob('stdo')
      stdo = globalvariables%stdo
      nlm = 2*l+1

      if (ifi .ne. 0) then
        strn1 = ' '
        call awrit3('%%%% rows %i cols %i complex %?#n#s#r#harm',
     .  strn1,len(strn1),0,nlm,nlm,sharm)
        strnl = strn1 // ' ' // strn // ' l=%i'//
     .  '%?#n#%-1j  site %i##'//
     .  '%?#(n>0)#  spin %i#'
C    .          '%?#(n>0)#  spin %i#%j#'
        do  isp = 1, nsp
          if (ipr .ge. ipr1) call awrit4(strnl,' ',len(strnl),ifi,l,
     .    ib,(ipr-ipr2+1)*(nsp-1),isp)
          if (ipr .lt. ipr2) return
          do  m1 = -l, l
            write(ifi,'(7(f12.7,2x))')
     .      (dmats(1,m1,m2,isp,iblu),m2=-l,l)
          enddo
          write(ifi,'(1x)')
          do  m1 = -l, l
            write(ifi,'(7(f12.7,2x))')
     .      (dmats(2,m1,m2,isp,iblu),m2=-l,l)
          enddo
        enddo
      else
        if (sharm .eq. 0) then
          strnl = strn // ' l=%i'//
     .    '%?#n#%-1j  site %i##'//
     .    '%?#(n>0)#  spin %i##, real harmonics'
        else
          strnl = strn // ' l=%i'//
     .    '%?#n#%-1j  site %i##'//
     .    '%?#(n>0)#  spin %i##, spherical harmonics'
        endif
C       Header: printout l, ib (if ib>0), spin (if nsp=2, ipr2>=ipr)
        do  isp = 1, nsp
          call info5(ipr1,0,0,strnl,l,ib,(ipr-ipr2+1)*(nsp-1),isp,0)
          if (ipr .lt. ipr2) return
          do  m1 = -l, l
            write(stdo,'(7(f9.5,2x))')
     .      (dmats(1,m1,m2,isp,iblu),m2=-l,l)
          enddo
          write(stdo,'(1x)')
          do  m1 = -l, l
            write(stdo,'(7(f9.5,2x))')
     .      (dmats(2,m1,m2,isp,iblu),m2=-l,l)
          enddo
        enddo

      endif

      end subroutine prdmts


