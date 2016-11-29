- (NSMethodSignature *) methodSignatureForSelector:(SEL)selector {
    fprintf(stderr, "[%s]S-%s\n", class_getName(self->isa), sel_getName(selector));
    return [super methodSignatureForSelector:selector];
}

- (BOOL) respondsToSelector:(SEL)selector {
    BOOL responds = [super respondsToSelector:selector];
    fprintf(stderr, "[%s]R%c%s\n", class_getName(self->isa), (responds ? '+' : '-'), sel_getName(selector));
    return responds;
}
