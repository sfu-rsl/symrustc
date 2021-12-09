int main(int argc, char *argv[]) {
  int a;
  int b;
  int c;
  if (argc == 0) {
    a = 0;
    if (argc == 1) {
      b = 1;
      if (argc == 2)
        c = 2;
      else
        c = argc;
    } else {
      b = argc;
      c = 0;
    }
  } else {
    a = argc;
    b = 0;
    c = 0;
  }
  return a + b + c;
}
