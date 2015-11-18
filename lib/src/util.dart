library tether.util;

import 'dart:math';

String generateHash({int length: 32}) {
  var hash = '';
  final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final random = new Random();
  while(hash.length < length)
    hash += chars[random.nextInt(chars.length - 1)];
  return hash;
}