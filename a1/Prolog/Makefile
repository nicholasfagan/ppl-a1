N=476117
$(N).sol:
	time swipl -qt main rush_hour_solve.pl $(N) | tee $(N).sol
test: $(N).sol
	../Python/rush_hour_check.py $(N).sol

