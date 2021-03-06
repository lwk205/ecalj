#define F90 1
#ifndef F90
      subroutine dqinv(cs,a,lda,nlev,n,w,ldw,ierr)
#else
      recursive subroutine dqinv(cs,a,lda,nlev,n,w,ldw,ierr)
#endif
C- Inversion of a real matrix using Strassen's algorithm
C ----------------------------------------------------------------
Ci Inputs:
Ci   a,lda matrix to be inverted and its leading dimension
Ci   n    rank of the matrix to be inverted
Ci   nlev is the maximum number of recursion levels allowed.
Ci         To avoid roundoff errors, nlev=2 is suggested.
Ci   w     is a real work array of dimension lda*n
Ci   cs:   if 's', a is assumed symmetric
Co Outputs:
Co   a^-1 is returned in a
Co   ierr is returned nonzero if matrix was not fully inverted.
Cr Remarks:
Cr   See Numerical Recipes, 2.11.
Cr   It is more efficient to allow inversion to proceed recursively,
Cr   if your compiler allows it.  Recursion proceeds provided nlev>0
Cr   and the dimension of the matrix to be inverted exceeds nmin.
Cr   The latter should be chosen where the tradoff between
Cr   the extra overhead and fewer O(N^3) operations takes place.
Cr   The AIX xlf90 compiler overwrites locally declared variables,
Cr   (use the -qrecur switch when compiling).  Compiling with AIX
Cr   code uncommented restores necessary variables after a recursive call.
Cr   (For debugging:)
Cr   mc -f4f16.10 a -split a 1,3,5 1,3,5  a11 -i -a r1  a21 r1 -x -a r2\
Cr   r2 a12 -x -a r4  r4 a22 -- -a r5  r5 -i -a r6  r1 a12 -x -a r3\
Cr   r3 r6 -x -a c12  r6 r2 -x -a c21  r3 c21 -x -a r7 r1 r7 -- -a c11\
Cr   r6 -s-1 -a c22 c11 c12 -ccat c21 c22 -ccat -rcat
C ----------------------------------------------------------------
C     implicit none
      integer n,lda,ldw,ierr,nlev
      double precision a(lda,1),w(ldw,2)
      double precision xx(2)
      character*1 cs
      integer nmin,m1,m2,i,j,isw,nmin0
      save nmin
#if DEBUG
      character*10 fmt
      data fmt /'(8f16.10)'/
#endif
      data nmin /32/

#if DEBUG
      print *, 'entering dqinv cs=',cs,' nlev,n=',nlev,n
#endif
      m1 = n/2
      m2 = n-m1

C --- Straight dgefa,di if n lt nmin ---
      if (n .le. nmin) then
        if (cs .ne. 's' .or. n .le. 2) then
          call dgefa(a,lda,n,w,ierr)
          if (ierr .ne. 0) return
          if (n .le. 2) then
            call dgedi(a,lda,n,w,xx,xx,1)
          else
            call dgedi(a,lda,n,w,xx,w(1,2),1)
          endif
        else
          call dsifa(a,lda,n,w,ierr)
          if (ierr .ne. 0) return
          call dsidi(a,lda,n,w,xx,i,w(1,2),1)
          do  10  i = 1, n
          do  10  j = 1, i
   10     a(i,j) = a(j,i)
        endif
#if DEBUG
        print *, 'exit dqinv, no Strassen'
#endif
        return
      endif

      if (lda .lt. n) call rx('dqinv: lda lt n')

C --- R1 = a11^-1 in a11 ---
#if RECUR | F90
      if (m1 .lt. nmin .or. nlev .eq. 0) then
#endif
        if (cs .eq. 's') then
          call dsifa(a,lda,m1,w,ierr)
          if (ierr .ne. 0) return
          call dsidi(a,lda,m1,w,xx,i,w(1,2),1)
          do  12  i = 1, n
          do  12  j = 1, i
   12     a(i,j) = a(j,i)
        else
          call dgefa(a,lda,m1,w,ierr)
          if (ierr .ne. 0) return
          call dgedi(a,lda,m1,w,xx,w(1,2),1)
        endif
#if RECUR | F90
      else
#if DEBUG
        print *, 'recursive call to dqinv n,m1,m2=',n,m1,m2
#endif
#if AIX | SUN_ULTRA 
        call dqinv(cs,a,lda,nlev-1,(m1),w,ldw,ierr)
        m1 = n/2
        m2 = n-m1
#else
        call dqinv(cs,a,lda,nlev-1,m1,w,ldw,ierr)
#endif
#if DEBUG
        print *, 'recursive call exit dqinv n,m1,m2=',n,m1,m2
#endif
        if (ierr .ne. 0) return
      endif
#endif
*     call ywrm(0,'R1',1,6,fmt,a,1,lda,m1,m1)

C --- R3 = R1 a12 in w  ---
      call dgemm('N','N',m1,m2,m1,1d0,a,lda,a(1,1+m1),lda,0d0,
     .  w,ldw)
*     call ywrm(0,'R3',1,6,fmt,w,1,ldw,m1,m2)

C --- R4 = a21 R3 = a21 a11^-1 a12 in w21  ---
      if (cs .eq. 's') then
        call dsmpy(m2,m1,a(1+m1,1),lda,w,ldw,0d0,w(1+m1,1),ldw)
      else
        call dgemm('N','N',m2,m2,m1,1d0,a(1+m1,1),lda,w,ldw,
     .    0d0,w(1+m1,1),ldw)
      endif
*     call ywrm(0,'R4',1,6,fmt,w(1+m1,1),1,ldw,m2,m2)

C --- -R5 = a22 - R4 = a22 - a21 a11^-1 a12 in a22 ---
      do  20  j = 1, m2
      do  20  i = 1, m2
   20 a(i+m1,j+m1) = a(i+m1,j+m1) - w(i+m1,j)
*     call ywrm(0,'-R5',1,6,fmt,a(1+m1,1+m1),1,lda,m2,m2)

C --- c22 = -R6 = -R5^-1 = (a22 - a21 a11^-1 a12)^-1 in a22 ---
#if RECUR | F90
      if (m2 .lt. nmin .or. nlev .eq. 0) then
#endif
        if (cs .eq. 's') then
          call dsifa(a(1+m1,1+m1),lda,m2,w(1+m1,1),ierr)
          if (ierr .ne. 0) return
          call dsidi(a(1+m1,1+m1),lda,m2,w(1+m1,1),xx,i,w(1+m1,2),1)
          do  16  i = 1, n
          do  16  j = 1, i
   16     a(i,j) = a(j,i)
        else
          call dgefa(a(1+m1,1+m1),lda,m2,w(1+m1,1),ierr)
          if (ierr .ne. 0) return
          call dgedi(a(1+m1,1+m1),lda,m2,w(1+m1,1),xx,w(1+m1,2),1)
        endif
#if RECUR | F90
      else
#if DEBUG
        print *, 'recursive call to dqinv n,m1,m2=',n,m1,m2
#endif
#if AIX | SUN_ULTRA 
        call dqinv(cs,a(1+m1,1+m1),lda,nlev-1,(m2),w(1+m1,1),ldw,ierr)
        m1 = n/2
        m2 = n-m1
#else
        call dqinv(cs,a(1+m1,1+m1),lda,nlev-1,m2,w(1+m1,1),ldw,ierr)
#endif
#if DEBUG
        print *, 'recursive call exit dqinv n,m1,m2=',n,m1,m2
#endif
        if (ierr .ne. 0) return
      endif
#endif
*     call ywrm(0,'-R6',1,6,fmt,a(1+m1,1+m1),1,lda,m2,m2)

C --- c12 = R3 * R6 = -a11^-1 a12 c22 in a12 ---
      call dgemm('N','N',m1,m2,m2,-1d0,w,ldw,a(1+m1,1+m1),lda,
     .  0d0,a(1,1+m1),lda)
*     call ywrm(0,'c12',1,6,fmt,a(1,1+m1),1,lda,m1,m2)

C --- Symmetric case: R2 = R3+ and c21=c12+ ---
      if (cs .eq. 's') then
        do  30  j = 1, m1
        do  30  i = 1, m2
   30   a(i+m1,j) = a(j,i+m1)

C   ... a11 -= R3 * R6 * R2 = R3 * c21
        call dgemm('N','N',m1,m1,m2,-1d0,w,ldw,
     .    a(1+m1,1),lda,1d0,a,lda)

C --- Nonsymmetric case ---
      else

C   --- R2 = a21 * R1 in w(2,1) ---
        call dgemm('N','N',m2,m1,m1,1d0,a(1+m1,1),lda,a,lda,0d0,
     .    w(1+m1,1),ldw)
*       call ywrm(0,'R2',1,6,fmt,w(1+m1,1),1,ldw,m2,m1)

C   --- c21 = R6 * R2 = -c22 a21 a11^-1 ---
        call dgemm('N','N',m2,m1,m2,-1d0,a(1+m1,1+m1),lda,
     .    w(1+m1,1),ldw,0d0,a(1+m1,1),lda)
*       call ywrm(0,'c21',1,6,fmt,a(1+m1,1),1,lda,m2,m1)

C   --- c11 = R1 - R3 * R6 * R2 = a11^-1 - c12 * R2 ---
        call dgemm('N','N',m1,m1,m2,-1d0,a(1,1+m1),lda,
     .    w(1+m1,1),ldw,1d0,a,lda)
*       call ywrm(0,'c11',1,6,fmt,a,1,lda,m1,m1)
      endif


#if DEBUG
      call yprm(.false.,'a^-1',1,6,fmt,ar,lda,n,lda,n)
      print *, 'exiting dqinv',n,m1,m2
#endif

      return

      entry dqinv0(nmin0,isw)
      if (isw .gt. 0) then
        nmin = nmin0
      else
        nmin0 = nmin
      endif


      end

