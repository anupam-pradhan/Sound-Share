/// Maps an Android API level (e.g. 35) to its marketing version (e.g. "15").
String androidReleaseName(int sdkInt) {
  const releases = {
    29: '10',
    30: '11',
    31: '12',
    32: '12L',
    33: '13',
    34: '14',
    35: '15',
    36: '16',
  };
  if (sdkInt <= 0) return '';
  return releases[sdkInt] ?? (sdkInt > 36 ? '${sdkInt - 20}' : 'API $sdkInt');
}
