      SUBROUTINE Z1BTF2( M, N, KL, KU, AB, LDAB, IPIV, IPIVC, INFO )
*
*  -- LAPACK routine (version 3.0) --
*     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
*     Courant Institute, Argonne National Lab, and Rice University
*     September 30, 1994
*
*     .. Scalar Arguments ..
      INTEGER            INFO, KL, KU, LDAB, M, N
*     ..
*     .. Array Arguments ..
      INTEGER            IPIV( * ), IPIVC( * )
      COMPLEX*16         AB( LDAB, * )
*     ..
*
*  Purpose
*  =======
*
*  Z1BTF2 is a variant of ZGBTF2, which additionally constrains pivots
*         to lie within specified subblocks specified by ipivc.
*
*  ZGBTF2 computes an LU factorization of a complex m-by-n band matrix
*  A using partial pivoting with row interchanges.
*
*  This is the unblocked version of the algorithm, calling Level 2 BLAS.
*
*  Arguments
*  =========
*
*  M       (input) INTEGER
*          The number of rows of the matrix A.  M >= 0.
*
*  N       (input) INTEGER
*          The number of columns of the matrix A.  N >= 0.
*
*  KL      (input) INTEGER
*          The number of subdiagonals within the band of A.  KL >= 0.
*
*  KU      (input) INTEGER
*          The number of superdiagonals within the band of A.  KU >= 0.
*
*  AB      (input/output) COMPLEX*16 array, dimension (LDAB,N)
*          On entry, the matrix A in band storage, in rows KL+1 to
*          2*KL+KU+1; rows 1 to KL of the array need not be set.
*          The j-th column of A is stored in the j-th column of the
*          array AB as follows:
*          AB(kl+ku+1+i-j,j) = A(i,j) for max(1,j-ku)<=i<=min(m,j+kl)
*
*          On exit, details of the factorization: U is stored as an
*          upper triangular band matrix with KL+KU superdiagonals in
*          rows 1 to KL+KU+1, and the multipliers used during the
*          factorization are stored in rows KL+KU+2 to 2*KL+KU+1.
*          See below for further details.
*
*  LDAB    (input) INTEGER
*          The leading dimension of the array AB.  LDAB >= 2*KL+KU+1.
*
*  IPIV    (output) INTEGER array, dimension (min(M,N))
*          The pivot indices; for 1 <= i <= min(M,N), row i of the
*          matrix was interchanged with row IPIV(i).
*
*  IPIVC   (input) INTEGER array, dimension indeterminate
*          The pivot constraints.  IPIVC partitions the matrix into
*          subblocks so that pivoting is restricted to occur within
*          a subblock.  IPIVC consists of an ordered list of indices.
*          It is an error for IPIVC(ic)<0  or for
*          IPIVC(ic)>=IPIVC(ic+1). The length of IPIVC is fixed by the
*          first entry for which IPIVC>=min(M,N). Thus for any column i
*          there is some ic which brackets column i; ie for which
*          IPIVC(ic) < i <= IPIVC(ic+1).  Pivoting for row i is
*          constrained to to be within this subblock.
*
*  INFO    (output) INTEGER
*          = 0: successful exit
*          < 0: if INFO = -i, the i-th argument had an illegal value
*          > 0: if INFO = +i, U(i,i) is exactly zero. The factorization
*               has been completed, but the factor U is exactly
*               singular, and division by zero will occur if it is used
*               to solve a system of equations.
*
*  Further Details
*  ===============
*
*  The band storage scheme is illustrated by the following example, when
*  M = N = 6, KL = 2, KU = 1:
*
*  On entry:                       On exit:
*
*      *    *    *    +    +    +       *    *    *   u14  u25  u36
*      *    *    +    +    +    +       *    *   u13  u24  u35  u46
*      *   a12  a23  a34  a45  a56      *   u12  u23  u34  u45  u56
*     a11  a22  a33  a44  a55  a66     u11  u22  u33  u44  u55  u66
*     a21  a32  a43  a54  a65   *      m21  m32  m43  m54  m65   *
*     a31  a42  a53  a64   *    *      m31  m42  m53  m64   *    *
*
*  Array elements marked * are not used by the routine; elements marked
*  + need not be set on entry, but are required by the routine to store
*  elements of U, because of fill-in resulting from the row
*  interchanges.
*
*  =====================================================================
*
*     .. Parameters ..
      COMPLEX*16         ONE, ZERO
      PARAMETER          ( ONE = ( 1.0D+0, 0.0D+0 ),
     $ZERO = ( 0.0D+0, 0.0D+0 ) )
*     ..
*     .. Local Scalars ..
      INTEGER            I, J, JP, JU, KM, KV, IC
*     ..
*     .. External Functions ..
      INTEGER            IZAMAX
      EXTERNAL           IZAMAX
*     ..
*     .. External Subroutines ..
      EXTERNAL           XERBLA, ZGERU, ZSCAL, ZSWAP
*     ..
*     .. Intrinsic Functions ..
      INTRINSIC          MAX, MIN
*     ..
*     .. Executable Statements ..
*
*     KV is the number of superdiagonals in the factor U, allowing for
*     fill-in.
*
      KV = KU + KL
*
*     Test the input parameters.
*
      INFO = 0
      IF( M.LT.0 ) THEN
      INFO = -1
      ELSE IF( N.LT.0 ) THEN
      INFO = -2
      ELSE IF( KL.LT.0 ) THEN
      INFO = -3
      ELSE IF( KU.LT.0 ) THEN
      INFO = -4
      ELSE IF( LDAB.LT.KL+KV+1 ) THEN
      INFO = -6
      END IF
      IF( INFO.NE.0 ) THEN
      CALL XERBLA( 'Z1BTF2', -INFO )
      RETURN
      END IF
*
*     Check pivot constraints
*
      DO  5  IC = 1, M
      IF (IPIVC(IC) .GE. M) GOTO 6
      IF (IPIVC(IC) .LT. 0 .or. IPIVC(IC) .GE. IPIVC(IC+1))
     .CALL XERBLA( 'Z1BTF2', -8 )
    5 CONTINUE
    6 CONTINUE
      IC = 1
*
*     Quick return if possible
*
      IF( M.EQ.0 .OR. N.EQ.0 )
     $RETURN
*
*     Gaussian elimination with partial pivoting
*
*     Set fill-in elements in columns KU+2 to KV to zero.
*
      DO 20 J = KU + 2, MIN( KV, N )
      DO 10 I = KV - J + 2, KL
      AB( I, J ) = ZERO
   10 CONTINUE
   20 CONTINUE
*
*     JU is the index of the last column affected by the current stage
*     of the factorization.
*
      JU = 1
*
      DO 40 J = 1, MIN( M, N )
*
*        Check for new pivot block
*
      IF (J .GT. IPIVC(IC)) IC = IC+1
*
*        Set fill-in elements in column J+KV to zero.
*
      IF( J+KV.LE.N ) THEN
      DO 30 I = 1, KL
      AB( I, J+KV ) = ZERO
   30 CONTINUE
      END IF
*
*        Find pivot and test for singularity. KM is the number of
*        subdiagonal elements in the current column.
*
      KM = MIN( KL, M-J )
C        JP = IZAMAX( KM+1, AB( KV+1, J ), 1 )
      JP = IZAMAX( MIN(KM,IPIVC(IC)-J)+1, AB( KV+1, J ), 1 )
      IPIV( J ) = JP + J - 1
      IF( AB( KV+JP, J ).NE.ZERO ) THEN
      JU = MAX( JU, MIN( J+KU+JP-1, N ) )
*
*           Apply interchange to columns J to JU.
*
      IF( JP.NE.1 )
     $CALL ZSWAP( JU-J+1, AB( KV+JP, J ), LDAB-1,
     $AB( KV+1, J ), LDAB-1 )
      IF( KM.GT.0 ) THEN
*
*              Compute multipliers.
*
      CALL ZSCAL( KM, ONE / AB( KV+1, J ), AB( KV+2, J ), 1 )
*
*              Update trailing submatrix within the band.
*
      IF( JU.GT.J )
     $CALL ZGERU( KM, JU-J, -ONE, AB( KV+2, J ), 1,
     $AB( KV, J+1 ), LDAB-1, AB( KV+1, J+1 ),
     $LDAB-1 )
      END IF
      ELSE
*
*           If pivot is zero, set INFO to the index of the pivot
*           unless a zero pivot has already been found.
*
      IF( INFO.EQ.0 )
     $INFO = J
      END IF
   40 CONTINUE
      RETURN
*
*     End of Z1BTF2
*
      END

