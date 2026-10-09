// Nonce helpers for Sign in with Apple (D6 step 2). The raw nonce goes to
// Supabase `signInWithIdToken(nonce:)`; its SHA-256 hex goes to Apple.

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';

/// Cryptographically random nonce of [length] characters.
String generateRawNonce([int length = 32]) {
  final rng = Random.secure();
  return List<String>.generate(length, (_) => _chars[rng.nextInt(_chars.length)]).join();
}

/// Lowercase hex SHA-256 of [input] (what Apple embeds in the identity token).
String sha256Hex(String input) => sha256.convert(utf8.encode(input)).toString();
