int main(int argc, char *argv[]) {
  int a;
  int b;
  if (argc == 0)
    a = 0;
  else
    a = argc;
  if (argc == 1)
    b = 1;
  else
    b = argc;
  return a + b;
}
