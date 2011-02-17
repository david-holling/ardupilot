/*
	This event will be called when the failsafe changes
	boolean failsafe reflects the current state
*/
void failsafe_event()
{
	if (failsafe == true){

		// This is how to handle a failsafe.
		switch(control_mode)
		{

		}
	}else{
		reset_I();
	}
}

void low_battery_event(void)
{
	send_message(SEVERITY_HIGH,"Low Battery!");
	set_mode(RTL);
	g.throttle_cruise = THROTTLE_CRUISE;
}


/*
4 simultaneous events
int event_original 		- original time in seconds
int event_countdown 	- count down to zero
byte event_countdown 	- ID for what to do
byte event_countdown	- how many times to loop, 0 = indefinite
byte event_value		- specific information for an event like PWM value
byte counterEvent		- undo the event if nescessary

count down each one


new event
undo_event
*/

void new_event(struct Location *cmd)
{
	Serial.print("New Event Loaded ");
	Serial.println(cmd->p1,DEC);
	

	if(cmd->p1 == STOP_REPEAT){
		Serial.println("STOP repeat ");
		event_id 			= NO_REPEAT;
		event_timer 		= -1;
		undo_event 			= 0;
		event_value 		= 0;
		event_delay 		= 0;
		event_repeat 		= 0; 	// convert seconds to millis
		event_undo_value	= 0;
		repeat_forever 		= 0;
	}else{
		// reset the event timer
		event_timer 		= millis();
		event_id 			= cmd->p1;
		event_value 		= cmd->alt;
		event_delay 		= cmd->lat;
		event_repeat 		= cmd->lng; 	// convert seconds to millis
		event_undo_value	= 0;
		repeat_forever = (event_repeat == 0) ? 1:0;	
	}
	
	/*
	Serial.print("event_id: ");
	Serial.println(event_id,DEC);
	Serial.print("event_value: ");
	Serial.println(event_value,DEC);
	Serial.print("event_delay: ");
	Serial.println(event_delay,DEC);
	Serial.print("event_repeat: ");
	Serial.println(event_repeat,DEC);
	Serial.print("event_undo_value: ");
	Serial.println(event_undo_value,DEC);
	Serial.print("repeat_forever: ");
	Serial.println(repeat_forever,DEC);
	Serial.print("Event_timer: ");
	Serial.println(event_timer,DEC);
	*/
	perform_event();
}

void perform_event()
{
	if (event_repeat > 0){
		event_repeat --;
	}
	switch(event_id) {
		case CH_4_TOGGLE:
			event_undo_value = g.rc_5.radio_out;
			APM_RC.OutputCh(CH_5, event_value); // send to Servos
			undo_event = 2;
			break;
		case CH_5_TOGGLE:
			event_undo_value = g.rc_6.radio_out;
			APM_RC.OutputCh(CH_6, event_value); // send to Servos
			undo_event = 2;
			break;
		case CH_6_TOGGLE:
			event_undo_value = g.rc_7.radio_out;
			APM_RC.OutputCh(CH_7, event_value); // send to Servos
			undo_event = 2;
			break;
		case CH_7_TOGGLE:
			event_undo_value = g.rc_8.radio_out;
			APM_RC.OutputCh(CH_8, event_value); // send to Servos
			undo_event = 2;
			event_undo_value = 1;
			break;
		case RELAY_TOGGLE:

			event_undo_value = PORTL & B00000100 ? 1:0;
			if(event_undo_value == 1){
				relay_A();
			}else{
				relay_B();
			}
			Serial.print("toggle relay ");
			Serial.println(PORTL,BIN);
			undo_event = 2;
			break;
			
	}
}

void relay_A()
{
	PORTL |= B00000100;
}

void relay_B()
{
	PORTL ^= B00000100;
}

void update_events()
{
	// repeating events
	if(undo_event == 1){
		perform_event_undo();
		undo_event = 0;
	}else if(undo_event > 1){
		undo_event --;
	}

	if(event_timer == -1) 
		return;
		
	if((millis() - event_timer) > event_delay){
		perform_event();
		
		if(event_repeat > 0 || repeat_forever == 1){
			event_repeat--;
			event_timer = millis();
		}else{
			event_timer = -1;
		}
	}
}

void perform_event_undo()
{
	switch(event_id) {
		case CH_4_TOGGLE:
			APM_RC.OutputCh(CH_5, event_undo_value); // send to Servos
			break;

		case CH_5_TOGGLE:
			APM_RC.OutputCh(CH_6, event_undo_value); // send to Servos
			break;

		case CH_6_TOGGLE:
			APM_RC.OutputCh(CH_7, event_undo_value); // send to Servos
			break;

		case CH_7_TOGGLE:
			APM_RC.OutputCh(CH_8, event_undo_value); // send to Servos
			break;

		case RELAY_TOGGLE:

			if(event_undo_value == 1){
				relay_A();
			}else{
				relay_B();
			}
			Serial.print("untoggle relay ");
			Serial.println(PORTL,BIN);
			break;
	}
}
