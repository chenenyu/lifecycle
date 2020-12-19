bool _enable = false;

void log(Object object) {
  if (_enable == true) {
    print(object);
  }
}
