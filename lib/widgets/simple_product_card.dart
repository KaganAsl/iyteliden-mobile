import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/models/response/image_response.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/services/image_service.dart';

class SimpleSelfProductCard extends StatelessWidget {

  final String jwt;
  final SimpleProductResponse product;
  final void Function()? onEdit;
  final void Function()? onDelete;
  final void Function()? onTap;

  const SimpleSelfProductCard({
    super.key,
    required this.jwt,
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12)),
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
                        return Image.network(img, fit: BoxFit.cover);
                      },
                    ),
                  ),
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
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
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