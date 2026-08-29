class CloudinaryService {
  static const String _baseUrl = 'https://res.cloudinary.com/renthubindia/image/upload';

  /// Returns an optimised image URL with transformation params
  static String optimise(String publicIdOrUrl, {int width = 400, int height = 300}) {
    if (publicIdOrUrl.isEmpty) return '';
    
    final publicId = publicIdOrUrl.contains('/upload/')
        ? publicIdOrUrl.split('/upload/').last
        : publicIdOrUrl;
        
    // If it's a completely external URL (e.g. google avatar fallback), return it directly
    if (publicIdOrUrl.startsWith('http') && !publicIdOrUrl.contains('cloudinary')) {
      return publicIdOrUrl;
    }
    
    return '$_baseUrl/w_$width,h_$height,c_fill,q_auto,f_auto/$publicId';
  }
}
