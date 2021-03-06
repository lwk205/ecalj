
      subroutine zhifa(a,lda,n,kpvt,info)
      integer lda,n,kpvt(1),info
      complex*16 a(lda,1)
c
c     zhifa factors a complex*16 hermitian matrix by elimination
c     with symmetric pivoting.
c
c     to solve  a*x = b , follow zhifa by zhisl.
c     to compute  inverse(a)*c , follow zhifa by zhisl.
c     to compute  determinant(a) , follow zhifa by zhidi.
c     to compute  inertia(a) , follow zhifa by zhidi.
c     to compute  inverse(a) , follow zhifa by zhidi.
c
c     on entry
c
c        a       complex*16(lda,n)
c                the hermitian matrix to be factored.
c                only the diagonal and upper triangle are used.
c
c        lda     integer
c                the leading dimension of the array  a .
c
c        n       integer
c                the order of the matrix  a .
c
c     on return
c
c        a       a block diagonal matrix and the multipliers which
c                were used to obtain it.
c                the factorization can be written  a = u*d*ctrans(u)
c                where  u  is a product of permutation and unit
c                upper triangular matrices , ctrans(u) is the
c                conjugate transpose of  u , and  d  is block diagonal
c                with 1 by 1 and 2 by 2 blocks.
c
c        kpvt    integer(n)
c                an integer vector of pivot indices.
c
c        info    integer
c                = 0  normal value.
c                = k  if the k-th pivot block is singular. this is
c                     not an error condition for this subroutine,
c                     but it does indicate that zhisl or zhidi may
c                     divide by zero if called.
c
c     linpack. this version dated 08/14/78 .
c     james bunch, univ. calif. san diego, argonne nat. lab.
c
c     subroutines and functions
c
c     blas zaxpy,zswap,izamax
c     fortran dabs,dmax1,dcmplx,dconjg,dsqrt
c
c     internal variables
c
      complex*16 ak,akm1,bk,bkm1,denom,mulk,mulkm1,t
      double precision absakk,alpha,colmax,rowmax
      integer imax,imaxp1,j,jj,jmax,k,km1,km2,kstep,izamax
      logical swap
c
      complex*16 zdum
      double precision cabs1
      double precision dreal,dimag
      complex*16 zdumr,zdumi
      dreal(zdumr) = zdumr
      dimag(zdumi) = (0.0d0,-1.0d0)*zdumi
      cabs1(zdum) = dabs(dreal(zdum)) + dabs(dimag(zdum))
c
c     initialize
c
c     alpha is used in choosing pivot block size.
      alpha = (1.0d0 + dsqrt(17.0d0))/8.0d0
c
      info = 0
c
c     main loop on k, which goes from n to 1.
c
      k = n
   10 continue
c
c        leave the loop if k=0 or k=1.
c
c     ...exit
      if (k .eq. 0) go to 200
      if (k .gt. 1) go to 20
      kpvt(1) = 1
      if (cabs1(a(1,1)) .eq. 0.0d0) info = 1
c     ......exit
      go to 200
   20 continue
c
c        this section of code determines the kind of
c        elimination to be performed.  when it is completed,
c        kstep will be set to the size of the pivot block, and
c        swap will be set to .true. if an interchange is
c        required.
c
      km1 = k - 1
      absakk = cabs1(a(k,k))
c
c        determine the largest off-diagonal element in
c        column k.
c
      imax = izamax(k-1,a(1,k),1)
      colmax = cabs1(a(imax,k))
      if (absakk .lt. alpha*colmax) go to 30
      kstep = 1
      swap = .false.
      go to 90
   30 continue
c
c           determine the largest off-diagonal element in
c           row imax.
c
      rowmax = 0.0d0
      imaxp1 = imax + 1
      do 40 j = imaxp1, k
        rowmax = dmax1(rowmax,cabs1(a(imax,j)))
   40 continue
      if (imax .eq. 1) go to 50
      jmax = izamax(imax-1,a(1,imax),1)
      rowmax = dmax1(rowmax,cabs1(a(jmax,imax)))
   50 continue
      if (cabs1(a(imax,imax)) .lt. alpha*rowmax) go to 60
      kstep = 1
      swap = .true.
      go to 80
   60 continue
      if (absakk .lt. alpha*colmax*(colmax/rowmax)) go to 70
      kstep = 1
      swap = .false.
      go to 80
   70 continue
      kstep = 2
      swap = imax .ne. km1
   80 continue
   90 continue
      if (dmax1(absakk,colmax) .ne. 0.0d0) go to 100
c
c           column k is zero.  set info and iterate the loop.
c
      kpvt(k) = k
      info = k
      go to 190
  100 continue
      if (kstep .eq. 2) go to 140
c
c           1 x 1 pivot block.
c
      if (.not.swap) go to 120
c
c              perform an interchange.
c
      call zswap(imax,a(1,imax),1,a(1,k),1)
      do 110 jj = imax, k
        j = k + imax - jj
        t = dconjg(a(j,k))
        a(j,k) = dconjg(a(imax,j))
        a(imax,j) = t
  110 continue
  120 continue
c
c           perform the elimination.
c
      do 130 jj = 1, km1
        j = k - jj
        mulk = -a(j,k)/a(k,k)
        t = dconjg(mulk)
        call zaxpy(j,t,a(1,k),1,a(1,j),1)
        a(j,j) = dcmplx(dreal(a(j,j)),0.0d0)
        a(j,k) = mulk
  130 continue
c
c           set the pivot array.
c
      kpvt(k) = k
      if (swap) kpvt(k) = imax
      go to 190
  140 continue
c
c           2 x 2 pivot block.
c
      if (.not.swap) go to 160
c
c              perform an interchange.
c
      call zswap(imax,a(1,imax),1,a(1,k-1),1)
      do 150 jj = imax, km1
        j = km1 + imax - jj
        t = dconjg(a(j,k-1))
        a(j,k-1) = dconjg(a(imax,j))
        a(imax,j) = t
  150 continue
      t = a(k-1,k)
      a(k-1,k) = a(imax,k)
      a(imax,k) = t
  160 continue
c
c           perform the elimination.
c
      km2 = k - 2
      if (km2 .eq. 0) go to 180
      ak = a(k,k)/a(k-1,k)
      akm1 = a(k-1,k-1)/dconjg(a(k-1,k))
      denom = 1.0d0 - ak*akm1
      do 170 jj = 1, km2
        j = km1 - jj
        bk = a(j,k)/a(k-1,k)
        bkm1 = a(j,k-1)/dconjg(a(k-1,k))
        mulk = (akm1*bk - bkm1)/denom
        mulkm1 = (ak*bkm1 - bk)/denom
        t = dconjg(mulk)
        call zaxpy(j,t,a(1,k),1,a(1,j),1)
        t = dconjg(mulkm1)
        call zaxpy(j,t,a(1,k-1),1,a(1,j),1)
        a(j,k) = mulk
        a(j,k-1) = mulkm1
        a(j,j) = dcmplx(dreal(a(j,j)),0.0d0)
  170 continue
  180 continue
c
c           set the pivot array.
c
      kpvt(k) = 1 - k
      if (swap) kpvt(k) = -imax
      kpvt(k-1) = kpvt(k)
  190 continue
      k = k - kstep
      go to 10
  200 continue
      return
      end

ccccccccccccccccccccccccccccccccc
      subroutine zhisl(a,lda,n,kpvt,b)
      integer lda,n,kpvt(1)
      complex*16 a(lda,1),b(1)
c
c     zhisl solves the complex*16 hermitian system
c     a * x = b
c     using the factors computed by zhifa.
c
c     on entry
c
c        a       complex*16(lda,n)
c                the output from zhifa.
c
c        lda     integer
c                the leading dimension of the array  a .
c
c        n       integer
c                the order of the matrix  a .
c
c        kpvt    integer(n)
c                the pivot vector from zhifa.
c
c        b       complex*16(n)
c                the right hand side vector.
c
c     on return
c
c        b       the solution vector  x .
c
c     error condition
c
c        a division by zero may occur if  zhico  has set rcond .eq. 0.0
c        or  zhifa  has set info .ne. 0  .
c
c     to compute  inverse(a) * c  where  c  is a matrix
c     with  p  columns
c           call zhifa(a,lda,n,kpvt,info)
c           if (info .ne. 0) go to ...
c           do 10 j = 1, p
c              call zhisl(a,lda,n,kpvt,c(1,j))
c        10 continue
c
c     linpack. this version dated 08/14/78 .
c     james bunch, univ. calif. san diego, argonne nat. lab.
c
c     subroutines and functions
c
c     blas zaxpy,zdotc
c     fortran dconjg,iabs
c
c     internal variables.
c
      complex*16 ak,akm1,bk,bkm1,zdotc,denom,temp
      integer k,kp
c
c     loop backward applying the transformations and
c     d inverse to b.
c
      k = n
   10 if (k .eq. 0) go to 80
      if (kpvt(k) .lt. 0) go to 40
c
c           1 x 1 pivot block.
c
      if (k .eq. 1) go to 30
      kp = kpvt(k)
      if (kp .eq. k) go to 20
c
c                 interchange.
c
      temp = b(k)
      b(k) = b(kp)
      b(kp) = temp
   20 continue
c
c              apply the transformation.
c
      call zaxpy(k-1,b(k),a(1,k),1,b(1),1)
   30 continue
c
c           apply d inverse.
c
      b(k) = b(k)/a(k,k)
      k = k - 1
      go to 70
   40 continue
c
c           2 x 2 pivot block.
c
      if (k .eq. 2) go to 60
      kp = iabs(kpvt(k))
      if (kp .eq. k - 1) go to 50
c
c                 interchange.
c
      temp = b(k-1)
      b(k-1) = b(kp)
      b(kp) = temp
   50 continue
c
c              apply the transformation.
c
      call zaxpy(k-2,b(k),a(1,k),1,b(1),1)
      call zaxpy(k-2,b(k-1),a(1,k-1),1,b(1),1)
   60 continue
c
c           apply d inverse.
c
      ak = a(k,k)/dconjg(a(k-1,k))
      akm1 = a(k-1,k-1)/a(k-1,k)
      bk = b(k)/dconjg(a(k-1,k))
      bkm1 = b(k-1)/a(k-1,k)
      denom = ak*akm1 - 1.0d0
      b(k) = (akm1*bk - bkm1)/denom
      b(k-1) = (ak*bkm1 - bk)/denom
      k = k - 2
   70 continue
      go to 10
   80 continue
c
c     loop forward applying the transformations.
c
      k = 1
   90 if (k .gt. n) go to 160
      if (kpvt(k) .lt. 0) go to 120
c
c           1 x 1 pivot block.
c
      if (k .eq. 1) go to 110
c
c              apply the transformation.
c
      b(k) = b(k) + zdotc(k-1,a(1,k),1,b(1),1)
      kp = kpvt(k)
      if (kp .eq. k) go to 100
c
c                 interchange.
c
      temp = b(k)
      b(k) = b(kp)
      b(kp) = temp
  100 continue
  110 continue
      k = k + 1
      go to 150
  120 continue
c
c           2 x 2 pivot block.
c
      if (k .eq. 1) go to 140
c
c              apply the transformation.
c
      b(k) = b(k) + zdotc(k-1,a(1,k),1,b(1),1)
      b(k+1) = b(k+1) + zdotc(k-1,a(1,k+1),1,b(1),1)
      kp = iabs(kpvt(k))
      if (kp .eq. k) go to 130
c
c                 interchange.
c
      temp = b(k)
      b(k) = b(kp)
      b(kp) = temp
  130 continue
  140 continue
      k = k + 2
  150 continue
      go to 90
  160 continue
      return
      end

