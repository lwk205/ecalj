######################################################
#
# $lmdir, which is defined in Makefile in ./ and in other 
# directories, should point at this root directory.
#
######################################################

#### jump to target (keep this as it is) ###
#target:	ALL


############################################
# Libraries BLAS LAPACK FFTW 
############################################
### For a case of ifort.
#eee = /home/takao/ecal
#LIBLOC = \
#  $(eee)/fftw-3.1.2/.libs/libfftw3.a \
#  $(eee)/BLASplusLAPACK/LAPACK_A/lapack_a.a \
#  $(eee)/BLASplusLAPACK/GotoBLAS/xerbla.o  \
#  $(eee)/BLASplusLAPACK/GotoBLAS/libgoto.a 
# -pthread 
# -lsvml
#
### for a case of MPI
#eee = /home/takao/ecal
#LIBLOC = \
#  $(eee)/fftw-3.1.2/.libs/libfftw3.a \
#  /home/takao/SCALAPACK/scalapack.a \
#  /home/takao/BLACS/LIB/blacsF77init_MPI-LINUX-0.a \
#  /home/takao/BLACS/LIB/blacs_MPI-LINUX-0.a \
#  $(eee)/BLASplusLAPACK/LAPACK_A/lapack_a.a \
#  $(eee)/BLASplusLAPACK/GotoBLAS/xerbla.o  \
#  $(eee)/BLASplusLAPACK/GotoBLAS/libgoto.a -pthread 
##-lsvml
#
### kino's case
# LIBLOC= -L$(HOME)/kit/fftw/fftw-3.1.2/.libs/ -lfftw3 \
# $(HOME)/kit/numericallib/LAPACK/lapack_core2gfortran.a \
# $(HOME)/kit/numericallib/LAPACK/blas_core2gfortran.a \
# $(HOME)/kit/numericallib/LAPACK/tmglib_core2gfortran.a \
# -L/opt/intel/fce/10.1.013/lib -lifcore -lguide -pthread

#LIBLOC= /opt/acml4.2.0/ifort64_mp/lib/libacml_mp.a -lfftw3 -lguide 
#LIBLOC= -static -lmkl_lapack64 -lmkl_em64t -lguide -lfftw3

# I had a problem in zgemm in pwmat for 4.2.0. Wrong normchk.dia
#LIBLOC= /opt/acml4.2.0/gfortran64/lib/libacml.a -lfftw3

# I had a problem in zgemm in pwmat. Wrong normchk.dia
#LIBLOC= /opt/acml4.1.0/gfortran64/lib/libacml.a -lfftw3



# ubuntu 9.10
LIBLOC= /usr/lib64/libfftw3.a /usr/lib64/liblapack.so.3gf /usr/lib64/libblas.a 

#ububntu apt-get install
#LIBLOC=  /usr/lib64/libfftw3.so.3.1.2 /usr/lib64/liblapack.a /usr/lib64/libblas-3.a 


# centos yum install. Zgemm did not work for larger size of matrix.
#LIBLOC = -L/usr/lib64/atlas/ /usr/lib64/atlas/liblapack.so.3 \
#          /usr/lib64/atlas/libf77blas.so.3 /usr/lib64/atlas/libcblas.so.3 \
#          /usr/lib64/atlas/libatlas.so.3 -lfftw3



############################################
# Fortran compiler and flags, and linker 
############################################
#FC = mpif90
#LK = mpif90
FC = f95
LK = 
#
# where is modules?
moddir = MODDIR/$(obj_path)
module = -J$(moddir) -I$(moddir)
#
FFLAGS = -E  -fomit-frame-pointer -funroll-loops  -ffast-math -ffixed-line-length-132 $(CPP_SW) $(module)
FFLAGS_LESS = -E -fomit-frame-pointer $(CPP_SW) -ffixed-line-length-132 $(module)
FFLAGS_LESS2 = -E -fomit-frame-pointer $(CPP_SW) -ffixed-line-length-132 $(module)
FFLAGS_LESS3 = -E -fomit-frame-pointer $(CPP_SW) -ffixed-line-length-132 $(module)
FFLAGS_NONE = -E  -ffixed-line-length-132 $(CPP_SW) $(module)

#FFLAGS = -O3  -fomit-frame-pointer -funroll-loops  -ffast-math  $(CPP_SW) $(module)
#FFLAGS_LESS = -O2 -fomit-frame-pointer $(CPP_SW) $(module)
#FFLAGS_LESS2 = -O1 -fomit-frame-pointer $(CPP_SW) $(module)
#FFLAGS_LESS3 = -O0 -fomit-frame-pointer $(CPP_SW) $(module)
#FFLAGS_NONE = -g  $(CPP_SW) $(module)
#
# safer option (debug)
#FFLAGS =      -g  $(CPP_SW) $(module)
#FFLAGS_LESS = -g  $(CPP_SW) $(module)
#FFLAGS_LESS2 = -g  $(CPP_SW) $(module)
#FFLAGS_LESS3 = -g  $(CPP_SW) $(module)
#FFLAGS_NONE = -g  $(CPP_SW) $(module)




###################################################
# CPP switches (instead of old ccomp procedure
###################################################
CPP_SW = -DHASIARGC  -DHASGETARG  -DFDATE  -DHASCPUTIME  -DHASGETENVIRONMENTVARIABLE  -DNOQUAD  -DNOT_OVERLAP_VAR

#
#MPI  case add  -UMPE -UMPIK -DMPI 
#
##MPIK case k-point parallelizaion in MPI add -UMPE -DMPIK -UMPI 



############################################
### Patches for intel ifc ##################
#
# Note that $SLATSM... are defined below.
#
############################################
## ... patch section for ./slatsm/slatsm.a
$(sla_obj_path)/huntx.o:slatsm/huntx.F
	$(FC) $(FFLAGS_LESS3) -c $< -o $@
 
$(sla_obj_path)/hunti.o: slatsm/hunti.F
	$(FC) $(FFLAGS_LESS3) -c $< -o $@
 
$(sla_obj_path)/polcof.o: slatsm/polcof.F
	$(FC) $(FFLAGS_LESS3) -c $< -o $@
 
$(sla_obj_path)/rdfiln.o: slatsm/rdfiln.F
	$(FC) $(FFLAGS_LESS3) -c $< -o $@

## patch section for ./subs/subs.a
$(subs_obj_path)/ropbes.o: subs/ropbes.F
	$(FC) $(FFLAGS_LESS3) -c $< -o $@
 
$(subs_obj_path)/ropyln.o: subs/ropyln.F
	$(FC) $(FFLAGS_LESS3) -c $< -o $@
 
$(subs_obj_path)/spcgrp.o: subs/spcgrp.F
	$(FC) $(FFLAGS_LESS) -c $< -o $@

### these modules requies no optimization ---> safer.
$(subs_obj_path)/m_toksw.o $(moddir)/m_toksw.mod $(moddir)/m_gtv.mod:	subs/m_toksw.F
	$(FC) $(FFLAGS_NONE) -c $< -o $(subs_obj_path)/m_toksw.o

$(subs_obj_path)/m_rdctrl.o $(moddir)/m_rdctrl.mod:	subs/m_rdctrl.F $(moddir)/m_struc_def.mod $(moddir)/m_toksw.mod $(moddir)/m_gtv.mod
	$(FC) $(FFLAGS_NONE) -c $< -o $(subs_obj_path)/m_rdctrl.o 

$(subs_obj_path)/m_rdctrlchk.o $(moddir)/m_rdctrlchk.mod:	subs/m_rdctrlchk.F $(moddir)/m_toksw.mod $(moddir)/m_gtv.mod
	$(FC) $(FFLAGS_NONE) -c $< -o $(subs_obj_path)/m_rdctrlchk.o

$(subs_obj_path)/m_struc_def.o $(moddir)/m_struc_def.mod:	subs/m_struc_def.F 
	$(FC) $(FFLAGS_NONE) -c $< -o $(subs_obj_path)/m_struc_def.o

$(subs_obj_path)/m_struc_func.o $(moddir)/m_struc_func.mod:	subs/m_struc_func.F
	$(FC) $(FFLAGS_NONE) -c $< -o $(subs_obj_path)/m_struc_func.o

#################################
$(fp_obj_path)/bndfp.o  : $(moddir)/m_rdctrl.mod $(moddir)/m_hamindex.mod $(moddir)/m_struc_def.mod fp/bndfp.F
	$(FC) $(FFLAGS) -c fp/bndfp.F -o $@	
$(gwd_obj_path)/bndfp.o  : $(moddir)/m_rdctrl.mod $(moddir)/m_hamindex.mod $(moddir)/m_struc_def.mod  gwd/bndfp.F
	$(FC) $(FFLAGS) -c gwd/bndfp.F -o $@
$(subs_obj_path)/hamfb3.o  : $(moddir)/m_hamindex.mod subs/hamfb3.F
	$(FC) $(FFLAGS) -c  subs/hamfb3.F -o $@
$(subs_obj_path)/rdctrl2.o  : $(moddir)/m_rdctrl.mod $(moddir)/m_gtv.mod subs/rdctrl2.F
	$(FC) $(FFLAGS) -c  subs/rdctrl2.F -o $@
$(subs_obj_path)/rdctrlchk.o  : $(moddir)/m_rdctrlchk.mod $(moddir)/m_gtv.mod subs/rdctrlchk.F
	$(FC) $(FFLAGS) -c  -o $@  subs/rdctrlchk.F
$(subs_obj_path)/rdsigm2.o  : $(moddir)/m_hamindex.mod subs/rdsigm2.F
	$(FC) $(FFLAGS) -c  -o $@  subs/rdsigm2.F
$(subs_obj_path)/rotwv.o  : $(moddir)/m_hamindex.mod subs/rotwv.F
	$(FC) $(FFLAGS) -c  -o $@  subs/rotwv.F
$(subs_obj_path)/struc_main.o  : $(moddir)/m_struc_def.mod $(moddir)/m_struc_func.mod subs/struc_main.F
	$(FC) $(FFLAGS) -c  -o $@ subs/struc_main.F
$(subs_obj_path)/struc_sub.o  : $(moddir)/m_struc_def.mod $(moddir)/m_struc_func.mod subs/struc_sub.F
	$(FC) $(FFLAGS) -c  -o $@ subs/struc_sub.F
$(subs_obj_path)/suham.o  $(moddir)/m_hamindex.mod : subs/suham.F
	$(FC) $(FFLAGS) -c  -o $(subs_obj_path)/suham.o  subs/suham.F
$(subs_obj_path)/readmtopara.o $(moddir)/m_gtv2.mod : subs/readmtopara.F
	$(FC) $(FFLAGS) -c  -o $(subs_obj_path)/readmtopara.o   subs/readmtopara.F

$(subs_obj_path)/rdsigm.o $(moddir)/m_psigd.mod : subs/rdsigm.F
	$(FC) $(FFLAGS) -c  -o $(subs_obj_path)/rdsigm.o subs/rdsigm.F
$(fp_obj_path)/hambls.o: $(moddir)/m_psigd.mod fp/hambls.F
	$(FC) $(FFLAGS) -c  -o $(fp_obj_path)/hambls.o fp/hambls.F



## ... patch section for ./fp/subs.a
$(fp_obj_path)/rhogkl.o: fp/rhogkl.F
	$(FC) $(FFLAGS_LESS) -c $< -o $@


################################################
# archiver (maybe fixed).
################################################
AR := ar
ARFLAGS := rv
RANLIB := ranlib


################################################
# program and libraries (choose one of sections; normal, MPI, or MPIK)
################################################
programs = lmf lmfa lmfgw lmdos lmchk lmf2gw lm67 rdcmd
SUBS   := libsubs.a
FP     := libfp.a
GWD    := libgwd.a
SLATSM := slatsm.a
#NC     = libnc.a
#TB     = libtb.a
#
### MPI case #####
#programs = lmf-MPI lmfgw-MPI
#SUBS   = libsubs-MPI.a
#FP     = libfp-MPI.a
#GWD    = libgwd-MPI.a
#SLATSM = slatsm-MPI.a
#
##### MPIK case ##
#programs = lmf-MPIK lmfgw-MPIK
#SUBS   = libsubs-MPIK.a 
#FP     = libfp-MPIK.a
#GWD    = libgwd-MPIK.a
#SLATSM = slatsm-MPI.a  #slatsm-MPI = slatsm-MPIK


### path to libraries (fixed) #########
LIBSUBS := subs/$(SUBS)
LIBFP   := fp/$(FP)
LIBGWD  := gwd/$(GWD)
LIBSLA  := slatsm/$(SLATSM)
#LIBNC   = nc/$(NC)
#LIBTB   = tb/$(TB)
#LIBES := $(LIBSLA) $(LIBLOC)


#???
# $(LIBSUBS): $(subs_obj)   fails
#	$(AR) $(ARFLAGS) $@ $(subs_obj)
#

subs/$(SUBS):$(subs_obj)
	$(AR) $(ARFLAGS) $@ $(subs_obj)

fp/$(FP): $(fp_obj)
	$(AR) $(ARFLAGS) $@ $(fp_obj)

slatsm/$(SLATSM): $(sla_obj)
	$(AR) $(ARFLAGS) $@ $(sla_obj)

gwd/$(GWD): $(gwd_obj)
	$(AR) $(ARFLAGS) $@ $(gwd_obj)

