module errorhandling

	implicit none

	character(len=4096) :: errstr

	integer, parameter :: UIMsg = 1
	integer, parameter :: MetaMsg = 2
	integer, parameter :: AppMsg = 3
	integer, parameter :: AppLibMsg = 4
	integer, parameter :: LibMsg = 5
	integer, parameter :: CoreMsg = 6
	integer, parameter :: KernelMsg = 7

	integer, parameter :: Silent = 0
	integer, parameter :: Sparse = 1
	integer, parameter :: Verbose = 2
	integer, parameter :: Noisy = 3
	integer, parameter :: Always = -99

	interface

	subroutine message( layer, level, text )
		integer, intent(in) :: layer, level
		character(len=*), intent(in), optional :: text
	end subroutine

	integer function verbosity( layer )
		integer, intent(in) :: layer
	end function

	subroutine fatal( codeID, text )
		character(len=*), intent(in) :: codeID
		character(len=*), intent(in), optional :: text
	end subroutine

	subroutine error( codeID, text )
		character(len=*), intent(in) :: codeID
		character(len=*), intent(in), optional :: text
	end subroutine

	subroutine warning( codeID, text )
		character(len=*), intent(in) :: codeID
		character(len=*), intent(in), optional :: text
	end subroutine

	end interface

end module

