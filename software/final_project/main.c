//ECE 385 USB Host Shield code
//based on Circuits-at-home USB Host code 1.x
//to be used for ECE 385 course materials
//Revised October 2020 - Zuofu Cheng

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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

static const BYTE p1_bytes[] = {26, 22, 4, 7, 20, 8}; // W,S,A,D,Q,E
static const BYTE p2_bytes[] = {12, 14, 13, 15, 24, 18}; // I,K,J,L,U,O

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


BYTE ai_player(BYTE key) {

	// aim lookup table [power][angle]
	static const int vx_lookup[8][9] = {
			{-4, -3, -3, -2, 0, 2, 3, 3, 4},
			{-5, -4, -4, -3, 0, 3, 4, 4 ,5},
			{-6, -5, -4, -3, 0, 3, 4, 5, 6},
			{-7, -6, -5, -3, 0, 3, 5, 6, 7},
			{-8, -7, -6, -3, 0, 3, 6, 7, 8},
			{-9, -8, -6, -4, 0, 4, 6, 8, 9},
			{-10, -9, -7, -4, 0, 4, 7, 9, 10},
			{-11, -10, -8, -4, 0, 4, 8, 10, 11} };
	static const int vy_lookup[8][9] = {
			{0, 2, 3, 3, 4, 3, 3, 2, 0},
			{0, 3, 4, 4, 5, 4, 4, 3, 0},
			{0, 3, 4, 5, 6, 5, 4, 3, 0},
			{0, 3, 5, 6, 7, 6, 5, 3, 0},
			{0, 3, 6, 7, 8, 7, 6, 3, 0},
			{0, 4, 6, 8, 9, 8, 6, 4, 0},
			{0, 4, 7, 9, 10, 9, 7, 4, 0},
			{0, 4, 8, 10, 11, 10, 8, 4, 0} };

	// global parameter increments
	static int cooldown;
	cooldown += 1;
	cooldown = cooldown % 120;

	// get player states
	int p1x = (int) *(p1_pos+1);
	int p1y = (int) *(p1_pos+0);
	int p1vx = (int) *(p1_vel+1);
	int p1vy = (int) *(p1_vel+0);
	int p2x = (int) *(p2_pos+1);
	int p2y = (int) *(p2_pos+0);
	int p2vx = (int) *(p2_vel+1);
	int p2vy = (int) *(p2_vel+0);

	// get bomb states
	int bx = (int) *(b1_pos+1);
	int by = (int) *(b1_pos+0);
	int bvx = (int) *(b1_vel+1);
	int bvy = (int) *(b1_vel+0);

	// dodging bombs
	int a = -bvy;
	int b = bvx;
	float m = (float) -a/b;
	float c = b * (m*bx-by);
	float dsq = pow(a*p2x+b*p2y+c,2) / (a*a+b*b);
	if (dsq < 1200){
		return 12;
	}

	// aiming
	int dx = p1x - p2x;
	int dy = p1y - p2y;
	float delta = 100;			// shot accuracy metric
	float delta_sgn = 0;		// shot accuracy metric (signed)
	static const float tol = 15;// accuracy tolerance
	int power_tgt = 0;
	int angle_tgt = 0;

	for (int i = 0; i < 6; i++){
		if (delta < tol){ break; }

		for (int j = 0; j < 9; j++){
			if (delta < tol){ break; }

			// implied a = 0.5 for the quadratic equation
			int b = (p1vy - vy_lookup[i][j]);
			int c = -dy;

			int det = b*b-2*c;
			if (det <= 0){ continue; }

			float t1 = (-b+sqrt((float)det));
			if (t1 < 0){ continue; }

			float t2 = (-b-sqrt((float)det));
			float t = (t2>0) ? t2 : t1;

			float delta0 = t * (vx_lookup[i][j]-p1vx) - dx;
			if ( (t >= 0) && (fabs(delta0) < delta) ){
				delta = fabs(delta0);
				delta_sgn = delta0;
				power_tgt = i;
				angle_tgt = j;
			}
		}
	}

	printf(" Power = %i(%i), Angle = %i(%i), Cooldown = %i, Delta_sgn = %f\n",
			*p2_pow, power_tgt, *p2_ang, angle_tgt, cooldown, delta_sgn);
	printf("      p1vy = %i, p2vy = %i   ", p1vy, p2vy);

	if (delta < tol && cooldown > 7){ // have targeting solution, start adjusting aim
		if (*p2_ang < angle_tgt){
//			printf("Turning right");
			return 18; // turn cw
		}
		else if (*p2_ang > angle_tgt){
//			printf("Turning left");
			return 24; // turn ccw
		}
		else if ( (*p2_pow != power_tgt)){
//			printf("Charging");
			return 14; // hold aim
		}
		else {
//			printf("Shooting");
			cooldown = 0;
			return key; // shoot
		}
	}
	else {				// no targeting solution, adjust position
		if (abs(p2vx) > 2) {
//			printf("Speeding at %i", p2vx);
			// do nothing if speeding
		}
		else if ( (cooldown%3==0) && (p2vy==0) ){
//			printf("Jumping");
			return 12; // jump to move quickly
		}
		else {
			if (delta_sgn < 0){ // p2x < 320+(320-p1x)/2+cooldown/2
//				printf("Moving right");
				return 15; // move right
			}
			else if (delta_sgn > 0){
//				printf("Moving left");
				return 13; // move left
			}
			else {
				if (dx > 0){
//					printf("Moving right");
					return 15; // move right
				}
				else if (dx < 0){
//					printf("Moving left");
					return 13; // move left
				}
			}
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
	BYTE ai_key;
	BYTE * k1;
	BYTE * k2;
	BOOT_MOUSE_REPORT buf;		//USB mouse report
	BOOT_KBD_REPORT kbdbuf;

	BYTE runningdebugflag = 0;//flag to dump out a bunch of information when we first get to USB_STATE_RUNNING
	BYTE errorflag = 0; //flag once we get an error device so we don't keep dumping out state info
	BYTE device;

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
//				printf("keycodes: ");
				for (int i = 0; i < 6; i++) {
//					printf("%x ", kbdbuf.keycode[i]);
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

				ai_key = ai_player(p2_key);
				p2_key = ai_key;

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
