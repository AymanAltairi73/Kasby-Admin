import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kasby_admin/core/utils/chat_attachment_helper.dart';

class ChatAttachmentImage extends StatefulWidget {
  const ChatAttachmentImage({
    super.key,
    required this.content,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 12,
  });

  final String content;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  @override
  State<ChatAttachmentImage> createState() => _ChatAttachmentImageState();
}

class _ChatAttachmentImageState extends State<ChatAttachmentImage> {
  late Future<String> _urlFuture;

  @override
  void initState() {
    super.initState();
    _urlFuture = ChatAttachmentHelper.resolveDisplayUrl(widget.content);
  }

  @override
  void didUpdateWidget(covariant ChatAttachmentImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _urlFuture = ChatAttachmentHelper.resolveDisplayUrl(widget.content);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _urlFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _placeholder();
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _error();
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: CachedNetworkImage(
            imageUrl: snapshot.data!,
            width: widget.width,
            height: widget.height,
            placeholder: (_, __) => _placeholder(),
            errorWidget: (_, __, ___) => _error(),
            fit: widget.fit,
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      width: widget.width ?? 150,
      height: widget.height ?? 150,
      color: Colors.white.withValues(alpha: 0.05),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _error() {
    return Container(
      width: widget.width ?? 150,
      height: widget.height ?? 150,
      color: Colors.white.withValues(alpha: 0.05),
      child: const Icon(Icons.broken_image_outlined, color: Colors.white54),
    );
  }
}
