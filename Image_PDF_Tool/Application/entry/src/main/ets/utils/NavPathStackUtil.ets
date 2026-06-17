export class NavPathStackUtil {
  static pushPathByName(pathStack: NavPathStack, name: string, param: Object | null): void {
    setTimeout((): void => {
      pathStack.pushPathByName(name, param);
    }, 0);
  }

  static pop(pathStack: NavPathStack): void {
    setTimeout((): void => {
      pathStack.pop();
    }, 0);
  }

  static clear(pathStack: NavPathStack): void {
    setTimeout((): void => {
      pathStack.clear();
    }, 0);
  }

  static clearAndPushPathByName(pathStack: NavPathStack, name: string, param: Object | null): void {
    setTimeout((): void => {
      pathStack.clear();
      pathStack.pushPathByName(name, param);
    }, 0);
  }
}
