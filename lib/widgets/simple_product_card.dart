import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/models/response/image_response.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/services/image_service.dart';
import 'package:iyteliden_mobile/utils/app_colors.dart';

class SimpleSelfProductCard extends StatelessWidget {

  final String jwt;
  final SimpleSelfProductResponse product;
  final void Function()? onEdit;
  final void Function()? onDelete;
  final void Function()? onTap;
  final String? productStatus;

  const SimpleSelfProductCard({
    super.key,
    required this.jwt,
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onTap,
    this.productStatus,
  });

  @override
  Widget build(BuildContext context) {
    bool isSold = (productStatus ?? product.productStatus)?.toUpperCase() == 'SOLD';

    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: product.coverImage == null ?
                    const Icon(Icons.image_not_supported_outlined, size: 48,)
                    : FutureBuilder<(ImageResponse?, ErrorResponse?)>(
                      future: ImageService().getImage(jwt, product.coverImage!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(),);
                        }
                        final img = snapshot.data?.$1?.url;
                        if (img == null) {
                          return const Icon(Icons.broken_image_outlined, size: 48,);
                        }
                        return Image.network(img, fit: BoxFit.contain);
                      },
                    ),
                  ),
                ),
                Divider(
                  thickness: 2,
                  color: Colors.black87,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4,),
                      Text(
                        "${product.price.toStringAsFixed(2)} ₺",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87
                        ),
                      ),
                      if (productStatus != null || product.productStatus != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            productStatus ?? product.productStatus!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSold ? Colors.redAccent : Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 4,
              right: 4,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, size: 20),
                padding: EdgeInsets.zero,
                itemBuilder: (_) {
                  List<PopupMenuEntry<String>> menuItems = [];
                  if (!isSold) {
                    menuItems.add(const PopupMenuItem(value: 'edit', child: Text('Edit')));
                  }
                  menuItems.add(const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))));
                  return menuItems;
                },
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit?.call();
                  } else if (value == 'delete') {
                    onDelete?.call();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleProductCard extends StatelessWidget {

  final String jwt;
  final SimpleProductResponse product;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? productStatus;

  const SimpleProductCard({
    super.key,
    required this.jwt,
    required this.product,
    this.isFavorite = false,
    this.onTap,
    this.onFavorite,
    this.onEdit,
    this.onDelete,
    this.productStatus,
  });

  @override
  Widget build(BuildContext context) {
    // Prioritize the productStatus prop, but fall back to product.productStatus
    final String? currentProductStatus = productStatus ?? product.productStatus;
    bool isSold = currentProductStatus?.toUpperCase() == 'SOLD';

    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: product.coverImage == null ?
                    const Icon(Icons.image_not_supported_outlined, size: 48,)
                    : FutureBuilder<(ImageResponse?, ErrorResponse?)>(
                      future: ImageService().getImage(jwt, product.coverImage!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                        }
                        final img = snapshot.data?.$1?.url;
                        if (img == null) {
                          return const Icon(Icons.broken_image_outlined, size: 48,);
                        }
                        return Image.network(img, fit: BoxFit.contain);
                      },
                    ),
                  ),
                ),
                Divider(
                  thickness: 2,
                  color: Colors.black87,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4,),
                      Text(
                        "${product.price.toStringAsFixed(2)} ₺",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87
                        ),
                      ),
                      if (currentProductStatus != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            currentProductStatus!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSold ? Colors.redAccent : Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Conditionally display the favorite button if not sold
            if (!isSold)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? AppColors.primary : AppColors.secondary,
                  ),
                  onPressed: onFavorite,
                ),
              ),
          ],
        ),
      ),
    );
  }
}