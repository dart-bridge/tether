part of tether.protocol;

abstract class Serializer {
  Object serialize(Object object);

  Object deserialize(Object object);
}