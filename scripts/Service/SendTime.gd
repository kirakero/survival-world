extends Reference

var counter = 0

func run(delta):
	if not Global.CLI.time.clock:
		return
		
	Global.CLI.time.tick(delta)
	
	# resync
	counter = counter + delta
	if counter < 0.5:
		return
	counter = 0.0
	
	Global.NET.tx_time_clisrv( 0 )
	
	















