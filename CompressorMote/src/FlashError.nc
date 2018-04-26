/**
 * Used to indicate flash errors.
 */
interface FlashError{
  /**
   * Signalled when an error has occurred.
   */
  event void onError(error_t error);
}