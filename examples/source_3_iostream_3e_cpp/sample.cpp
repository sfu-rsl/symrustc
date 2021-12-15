#include <iostream>

int main(int argc, char *argv[]) {
  std::string name;
  std::cin >> name;
  if (name == "root")
    return 1;
  if (name == "two")
    return 2;
  return 0;
}
