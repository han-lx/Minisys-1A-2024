// display num at loc (0 based), num 16 = U, num 17 = Y
void display_digit(int loc, int num) {
  // max-min clip
  if (num < 0) num = 0;
  if (num > 17) num = 17;
  if (loc < 0) loc = 0;
  if (loc > 7) loc = 7;
  // deliver data
  $0xFFFFFC00 = num;
  $0xFFFFFC04 = loc;
  return;
}

// display value as decimal at 7seg, must >= 0
void smart_display_digit(int value) {
  int current_loc;
  int data;
  int remainder;
  current_loc = 0;
  data = value;
  while (data >= 0 && current_loc < 8) {
    remainder = data % 10;
    data = data / 10;
    display_digit(current_loc, remainder);
    current_loc = current_loc + 1;
  }
  current_loc = 8;
  display_digit(current_loc, 0);
  return;
}

int main(void) {
  int countdown;
  int loop;
  countdown = 20;
  
  while (countdown >= 0) {
    loop = 12500;
    while (loop > 0) {
        loop = loop - 1;
        smart_display_digit(countdown);
    }
    countdown = countdown - 1;
  }
  
  return 0;
}