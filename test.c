void delay(void) {
  int c;
  c = 30000;
  while (c > 0) {
    c = c - 1;
  }
  return;
}
void main(void) {
  int led;
  led = 0;
  while (1) {
    led = led + 1;
    $0xfffffc60 = led;
    $0xfffffc62 = led >> 16;
    if (led > 10) led = 0;
    delay();
  }
  return;
}

