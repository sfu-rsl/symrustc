int main(int argc, char *argv[]) {
  int a;
  int b;
  int c;
  if (argc == 0)
    a = 0;
  else
    a = argc;
  if (argc == 1)
    b = 1;
  else
    b = argc;
  if (argc == 2)
    c = 2;
  else
    c = argc;
  return a + b + c;
}
