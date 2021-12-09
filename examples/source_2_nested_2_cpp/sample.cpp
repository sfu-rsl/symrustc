int main(int argc, char *argv[]) {
  int a;
  int b;
  if (argc == 0) {
    a = 0;
    if (argc == 1)
      b = 1;
    else
      b = argc;
  } else {
    a = argc;
    b = 0;
  }
  return a + b;
}
