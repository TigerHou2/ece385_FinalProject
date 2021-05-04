//ECE 385 USB Host Shield code
//based on Circuits-at-home USB Host code 1.x
//to be used for ECE 385 course materials
//Revised October 2020 - Zuofu Cheng

#include <stdio.h>
#include <math.h>
#include "system.h"
#include "altera_avalon_spi.h"
#include "altera_avalon_spi_regs.h"
#include "altera_avalon_pio_regs.h"
#include "sys/alt_irq.h"
#include "usb_kb/GenericMacros.h"
#include "usb_kb/GenericTypeDefs.h"
#include "usb_kb/HID.h"
#include "usb_kb/MAX3421E.h"
#include "usb_kb/transfer.h"
#include "usb_kb/usb_ch9.h"
#include "usb_kb/USB.h"

extern HID_DEVICE hid_device;

static BYTE addr = 1; 				//hard-wired USB address
const char* const devclasses[] = { " Uninitialized", " HID Keyboard", " HID Mouse", " Mass storage" };

static BYTE p1_bytes[] = {26, 22, 4, 7, 20, 8}; // W,S,A,D,Q,E
static BYTE p2_bytes[] = {12, 14, 13, 15, 24, 18}; // I,K,J,L,U,O

// P1 position and velocity
volatile SHORT *p1_pos = (SHORT*) P1_POS_BASE;
volatile SHORT *p1_vel = (SHORT*) P1_VEL_BASE;

// AI position and velocity
volatile SHORT *p2_pos = (SHORT*) P2_POS_BASE;
volatile SHORT *p2_vel = (SHORT*) P2_VEL_BASE;

// P1 projectile position and velocity
volatile SHORT *b1_pos = (SHORT*) B1_POS_BASE;
volatile SHORT *b1_vel = (SHORT*) B1_VEL_BASE;

// P2 aim power and angle
volatile SHORT *p2_pow = (SHORT*) AIM_BASE + 1;
volatile SHORT *p2_ang = (SHORT*) AIM_BASE;

// aim tracking
int cooldown = 100;

// aim lookup table [power][angle]
float vx_lookup[8][9] = {	{-4, -3, -3, -2, 0, 2, 3, 3, 4},
							{-5, -4, -4, -3, 0, 3, 4, 4 ,5},
							{-6, -5, -4, -3, 0, 3, 4, 5, 6},
							{-7, -6, -5, -3, 0, 3, 5, 6, 7},
							{-8, -7, -6, -3, 0, 3, 6, 7, 8},
							{-9, -8, -6, -4, 0, 4, 6, 8, 9},
							{-10, -9, -7, -4, 0, 4, 7, 9, 10},
							{-11, -10, -8, -4, 0, 4, 8, 10, 11} };
float vy_lookup[8][9] = {	{0, 2, 3, 3, 4, 3, 3, 2, 0},
							{0, 3, 4, 4, 5, 4, 4, 3, 0},
							{0, 3, 4, 5, 6, 5, 4, 3, 0},
							{0, 3, 5, 6, 7, 6, 5, 3, 0},
							{0, 3, 6, 7, 8, 7, 6, 3, 0},
							{0, 4, 6, 8, 9, 8, 6, 4, 0},
							{0, 4, 7, 9, 10, 9, 7, 4, 0},
							{0, 4, 8, 10, 11, 10, 8, 4, 0} };


BYTE ai_player(BYTE key) {

	// global parameter increments
	cooldown += 1;
	cooldown = cooldown % 120;

	// get player states
	float p1x = (float) *(p1_pos+1);
	float p1y = (float) *(p1_pos+0);
	float p1vx = (float) *(p1_vel+1);
	float p1vy = (float) *(p1_vel+0);
	float p2x = (float) *(p2_pos+1);
	float p2y = (float) *(p2_pos+0);
	float p2vx = (float) *(p2_vel+1);
	float p2vy = (float) *(p2_vel+0);

	// get bomb states
	float bx = (float) *(b1_pos+1);
	float by = (float) *(b1_pos+0);
	float bvx = (float) *(b1_vel+1);
	float bvy = (float) *(b1_vel+0);

	// dodging bombs
	float a = -bvy;
	float b = bvx;
	float m = -a/b;
	float c = b * (m*bx-by);
	float dsq = pow(a*p2x+b*p2y+c,2) / (a*a+b*b);
	if (dsq < 700){
		return (BYTE) 12;
	}

	// aiming
	float dx = p1x - p2x;
	float dy = p1y - p2y;
	float delta = 100;
	float delta0 = 0;
	float delta_sgn = 0;
	float dist_x = (dx>=0) ? dx - 8 : dx + 8;
	int power_tgt = 0;
	int angle_tgt = 0;

	for (int i = 0; i < 6; i++){ // search in power levels 0-5 (ignore highest power)
		for (int j = 0; j < 9; j++){
			float den = vx_lookup[i][j] - p1vx;
			if ( (fabs(den) > 0.1) && (vx_lookup[i][j]*dx > 0) ){
				float t = dist_x / den;
				delta0 = p1vy + dy/t - t - vy_lookup[i][j] - 1;
				if ( (t > 0) && (fabs(delta0) < delta) ){
					delta = fabs(delta0);
					delta_sgn = delta0;
					power_tgt = (i-1)%8;
					angle_tgt = j;
				}
			}
		}
	}

	printf(" Power = %i(%i), Angle = %i(%i), Cooldown = %i, Delta = %f\n",
			*p2_pow, power_tgt, *p2_ang, angle_tgt, cooldown, delta);

	if (delta < 12 && cooldown > 7){ // have targeting solution, start adjusting aim
		if (*p2_ang < angle_tgt){
			printf("Turning right");
			return (BYTE) 18; // turn cw
		}
		else if (*p2_ang > angle_tgt){
			printf("Turning left");
			return (BYTE) 24; // turn ccw
		}
		else if ( (*p2_pow != (power_tgt-1)%8)){
			printf("Charging");
			return (BYTE) 14; // hold aim
		}
		else {
			printf("Shooting");
			cooldown = 0;
			return key; // shoot
		}
	}
	else {				// no targeting solution, adjust position
		if (fabs(p2vx) > 2) {
			printf("Speeding at %f", p2vx);
			// do nothing if speeding
		}
		else if ( (p2vy == 0) && (p2vx == 0) ) {
			printf("Jumping");
			return (BYTE) 12; // jump to move quickly
		}
		else if (p2x < 320+(320-p1x)/2+cooldown/2){
			printf("Moving right");
			return (BYTE) 15; // move right
		}
		else {
			printf("Moving left");
			return (BYTE) 13; // move left
		}
	}

	return key;

}

BYTE GetDriverandReport() {
	BYTE i;
	BYTE rcode;
	BYTE device = 0xFF;
	BYTE tmpbyte;

	DEV_RECORD* tpl_ptr;
	printf("Reached USB_STATE_RUNNING (0x40)\n");
	for (i = 1; i < USB_NUMDEVICES; i++) {
		tpl_ptr = GetDevtable(i);
		if (tpl_ptr->epinfo != NULL) {
			printf("Device: %d", i);
			printf("%s \n", devclasses[tpl_ptr->devclass]);
			device = tpl_ptr->devclass;
		}
	}
	//Query rate and protocol
	rcode = XferGetIdle(addr, 0, hid_device.interface, 0, &tmpbyte);
	if (rcode) {   //error handling
		printf("GetIdle Error. Error code: ");
		printf("%x \n", rcode);
	} else {
		printf("Update rate: ");
		printf("%x \n", tmpbyte);
	}
	printf("Protocol: ");
	rcode = XferGetProto(addr, 0, hid_device.interface, &tmpbyte);
	if (rcode) {   //error handling
		printf("GetProto Error. Error code ");
		printf("%x \n", rcode);
	} else {
		printf("%d \n", tmpbyte);
	}
	return device;
}

void setLED(int LED) {
	IOWR_ALTERA_AVALON_PIO_DATA(LEDS_PIO_BASE,
			(IORD_ALTERA_AVALON_PIO_DATA(LEDS_PIO_BASE) | (0x001 << LED)));
}

void clearLED(int LED) {
	IOWR_ALTERA_AVALON_PIO_DATA(LEDS_PIO_BASE,
			(IORD_ALTERA_AVALON_PIO_DATA(LEDS_PIO_BASE) & ~(0x001 << LED)));

}

void printSignedHex0(signed char value) {
	BYTE tens = 0;
	BYTE ones = 0;
	WORD pio_val = IORD_ALTERA_AVALON_PIO_DATA(HEX_DIGITS_PIO_BASE);
	if (value < 0) {
		setLED(11);
		value = -value;
	} else {
		clearLED(11);
	}
	//handled hundreds
	if (value / 100)
		setLED(13);
	else
		clearLED(13);

	value = value % 100;
	tens = value / 10;
	ones = value % 10;

	pio_val &= 0x00FF;
	pio_val |= (tens << 12);
	pio_val |= (ones << 8);

	IOWR_ALTERA_AVALON_PIO_DATA(HEX_DIGITS_PIO_BASE, pio_val);
}

void printSignedHex1(signed char value) {
	BYTE tens = 0;
	BYTE ones = 0;
	DWORD pio_val = IORD_ALTERA_AVALON_PIO_DATA(HEX_DIGITS_PIO_BASE);
	if (value < 0) {
		setLED(10);
		value = -value;
	} else {
		clearLED(10);
	}
	//handled hundreds
	if (value / 100)
		setLED(12);
	else
		clearLED(12);

	value = value % 100;
	tens = value / 10;
	ones = value % 10;
	tens = value / 10;
	ones = value % 10;

	pio_val &= 0xFF00;
	pio_val |= (tens << 4);
	pio_val |= (ones << 0);

	IOWR_ALTERA_AVALON_PIO_DATA(HEX_DIGITS_PIO_BASE, pio_val);
}

void setKeycode(WORD keycode)
{
//	IOWR_ALTERA_AVALON_PIO_DATA(0x8002000, keycode);
	IOWR_ALTERA_AVALON_PIO_DATA(KEYCODE_BASE, keycode);
}
int main() {
	BYTE rcode;
	BYTE allKeycodes[] = "ABCDEF";
	BYTE p1_key;
	BYTE p2_key;
	BYTE * k1;
	BYTE * k2;
	BOOT_MOUSE_REPORT buf;		//USB mouse report
	BOOT_KBD_REPORT kbdbuf;

	BYTE runningdebugflag = 0;//flag to dump out a bunch of information when we first get to USB_STATE_RUNNING
	BYTE errorflag = 0; //flag once we get an error device so we don't keep dumping out state info
	BYTE device;
	WORD keycode;

	printf("initializing MAX3421E...\n");
	MAX3421E_init();
	printf("initializing USB...\n");
	USB_init();
	while (1) {
		printf(".");
		MAX3421E_Task();
		for (int i = 0; i < 50; i++) {/* do nothing, artificial delay*/}
		USB_Task();

		if (GetUsbTaskState() == USB_STATE_RUNNING) {
			if (!runningdebugflag) {
				runningdebugflag = 1;
				setLED(9);
				device = GetDriverandReport();
			} else if (device == 1) {
				//run keyboard debug polling
				rcode = kbdPoll(&kbdbuf);
				if (rcode == hrNAK) {
					continue; //NAK means no new data
				} else if (rcode) {
					printf("Rcode: ");
					printf("%x \n", rcode);
					continue;
				}
				printf("keycodes: ");
				for (int i = 0; i < 6; i++) {
					printf("%x ", kbdbuf.keycode[i]);
					*(allKeycodes+i) = kbdbuf.keycode[i];
				}

				/* send in two keycodes (concatenated together)
				 * specifically, check all six keycodes for viable inputs
				 * for players P1 and P2, place the first viable one for
				 * each respective player into the output
				 *
				 * P1 viable codes:
				 * W (0x1A), S (0x16), A (0x04), D (0x07)
				 * Q (0x14), E (0x08)
				 *
				 * P2 viable codes:
				 * I (0x0C), K (0x0E), J (0x0D), L (0x0F)
				 * U (0x18), O (0x12)
				 *
				 */

				k1 = strpbrk(p1_bytes, allKeycodes);
				if ( k1 != 0 ) {
					p1_key = *k1;
				} else {
					p1_key = 0x00;
				}
				k2 = strpbrk(p2_bytes, allKeycodes);
				if ( k2 != 0 ) {
					p2_key = *k2;
				} else {
					p2_key = 0x00;
				}

				p2_key = ai_player(p2_key);

				setKeycode( (p1_key << 8) + p2_key );

				printSignedHex0(p1_key);
				printSignedHex1(p2_key);
				printf("\n");
			}

			else if (device == 2) {
				rcode = mousePoll(&buf);
				if (rcode == hrNAK) {
					//NAK means no new data
					continue;
				} else if (rcode) {
					printf("Rcode: ");
					printf("%x \n", rcode);
					continue;
				}
				printf("X displacement: ");
				printf("%d ", (signed char) buf.Xdispl);
				printSignedHex0((signed char) buf.Xdispl);
				printf("Y displacement: ");
				printf("%d ", (signed char) buf.Ydispl);
				printSignedHex1((signed char) buf.Ydispl);
				printf("Buttons: ");
				printf("%x\n", buf.button);
				if (buf.button & 0x04)
					setLED(2);
				else
					clearLED(2);
				if (buf.button & 0x02)
					setLED(1);
				else
					clearLED(1);
				if (buf.button & 0x01)
					setLED(0);
				else
					clearLED(0);
			}
		} else if (GetUsbTaskState() == USB_STATE_ERROR) {
			if (!errorflag) {
				errorflag = 1;
				clearLED(9);
				printf("USB Error State\n");
				//print out string descriptor here
			}
		} else //not in USB running state
		{

			printf("USB task state: ");
			printf("%x\n", GetUsbTaskState());
			if (runningdebugflag) {	//previously running, reset USB hardware just to clear out any funky state, HS/FS etc
				runningdebugflag = 0;
				MAX3421E_init();
				USB_init();
			}
			errorflag = 0;
			clearLED(9);
		}
		for (int i = 0; i < 50; i++) {/* do nothing, artificial delay*/}
	}
	printf("You should not have reached this point.");
	return 0;
}
