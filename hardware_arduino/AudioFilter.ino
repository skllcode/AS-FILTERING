/*
 * Course Project 1 - Audio Signal Filtering (Hardware Implementation)
 * Platform: Arduino Uno / Mega
 *
 * Description:
 *   Real-time IIR Butterworth Low-Pass Filter implementation
 *   Cutoff Frequency: 5000 Hz
 *   Filter Order: 6 (implemented as 3 cascaded second-order sections)
 *   Sampling Frequency: 44100 Hz (via Timer interrupt)
 *
 * Hardware Connections:
 *   - Audio Input:  A0 (Analog Input, via audio amplifier/preamp circuit)
 *   - Audio Output: DAC0 (Arduino Due) or PWM pin 9 (Arduino Uno)
 *   - GND:          Common ground with audio source
 *
 * Block Schematic:
 *   [Mic/Audio Source] -> [Preamp + DC Bias] -> [A0 (ADC)]
 *       -> [Arduino (IIR Filter)] -> [DAC/PWM Output]
 *       -> [Low-Pass RC Filter] -> [Audio Amplifier] -> [Speaker]
 */

// ===================== Configuration =====================
#define SAMPLE_RATE     44100   // Sampling frequency (Hz)
#define ADC_PIN         A0      // Analog input pin
#define OUTPUT_PIN      9       // PWM output pin (Uno) or DAC0 (Due)
#define ADC_RESOLUTION  1024    // 10-bit ADC
#define NUM_SECTIONS    3       // Number of second-order sections (SOS)

// ===================== Filter Coefficients =====================
// IIR Butterworth Low-Pass Filter, Order 6, fc = 5000 Hz, Fs = 44100 Hz
// Implemented as 3 cascaded Second-Order Sections (SOS)
// Designed in MATLAB: [sos, g] = tf2sos(b_iir, a_iir);
//
// Each section: H(z) = (b0 + b1*z^-1 + b2*z^-2) / (1 + a1*z^-1 + a2*z^-2)

// SOS coefficients [b0, b1, b2, a1, a2] for each section
const float sos[NUM_SECTIONS][5] = {
    // Section 1
    { 1.0,  2.0,  1.0,  -0.4327,  0.1294 },
    // Section 2
    { 1.0,  2.0,  1.0,  -0.5765,  0.3519 },
    // Section 3
    { 1.0,  2.0,  1.0,  -0.8758,  0.7573 }
};

// Gain for each section
const float gain[NUM_SECTIONS] = { 0.1742, 0.1939, 0.2204 };

// Overall gain
const float overall_gain = 1.0;

// ===================== Filter State Variables =====================
// Delay buffers for each SOS (Direct Form II Transposed)
float w[NUM_SECTIONS][2] = {{0}};  // w[section][delay_index]

// ===================== Volatile Variables for ISR =====================
volatile int adc_value = 0;
volatile int output_value = 0;
volatile bool sample_ready = false;

// ===================== Setup =====================
void setup() {
    Serial.begin(115200);
    Serial.println("Audio Signal Filtering - Arduino Implementation");
    Serial.println("IIR Butterworth LPF, Order 6, fc = 5000 Hz");
    Serial.println("Fs = 44100 Hz");

    // Configure ADC
    pinMode(ADC_PIN, INPUT);

    // Configure output
    pinMode(OUTPUT_PIN, OUTPUT);

    // Setup Timer1 for sampling at 44100 Hz
    setupTimer1();

    Serial.println("Filter running...");
}

// ===================== Timer1 Setup (44100 Hz) =====================
void setupTimer1() {
    noInterrupts();

    TCCR1A = 0;
    TCCR1B = 0;
    TCNT1  = 0;

    // Compare match value for 44100 Hz
    // OCR1A = (16MHz / (prescaler * 44100)) - 1
    // With prescaler = 1: OCR1A = (16000000 / 44100) - 1 = 362
    OCR1A = 362;

    TCCR1B |= (1 << WGM12);   // CTC mode
    TCCR1B |= (1 << CS10);    // Prescaler = 1
    TIMSK1 |= (1 << OCIE1A);  // Enable compare interrupt

    // Setup Fast PWM on Timer2 for audio output (pin 9 or 3)
    TCCR2A = _BV(COM2A1) | _BV(WGM21) | _BV(WGM20);  // Fast PWM
    TCCR2B = _BV(CS20);  // No prescaler

    interrupts();
}

// ===================== Timer1 ISR (Sampling) =====================
ISR(TIMER1_COMPA_vect) {
    // Read ADC
    adc_value = analogRead(ADC_PIN);
    sample_ready = true;
}

// ===================== IIR Filter Function =====================
float applyIIRFilter(float input) {
    float x = input;

    // Process through each second-order section
    for (int i = 0; i < NUM_SECTIONS; i++) {
        float b0 = sos[i][0] * gain[i];
        float b1 = sos[i][1] * gain[i];
        float b2 = sos[i][2] * gain[i];
        float a1 = sos[i][3];
        float a2 = sos[i][4];

        // Direct Form II Transposed
        float y = b0 * x + w[i][0];
        w[i][0] = b1 * x - a1 * y + w[i][1];
        w[i][1] = b2 * x - a2 * y;

        x = y;  // Output of this section is input to next
    }

    return x * overall_gain;
}

// ===================== Main Loop =====================
void loop() {
    if (sample_ready) {
        sample_ready = false;

        // Convert ADC value to float (-1.0 to 1.0 range)
        float input = ((float)adc_value / (ADC_RESOLUTION / 2)) - 1.0;

        // Apply IIR Butterworth Low-Pass Filter
        float filtered = applyIIRFilter(input);

        // Clamp output to valid range
        if (filtered > 1.0) filtered = 1.0;
        if (filtered < -1.0) filtered = -1.0;

        // Convert back to PWM output (0-255)
        output_value = (int)((filtered + 1.0) * 127.5);

        // Write to PWM output
        OCR2A = output_value;  // Direct register write for speed
    }
}
