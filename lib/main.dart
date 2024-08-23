import 'package:flutter/material.dart';
import 'package:test556/images.dart';

final duration = Duration(milliseconds: 1000);
final Size listItemSize = Size(170, 260);

void main() => runApp(MaterialApp(home: MyHomePage()));

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final List<String> imageUrls = List.of(ImageUtils.imageUrls);
  late String selectedUrl;
  late String prevUrl;
  bool isFirstLoad = true;
  final _myList = GlobalKey<AnimatedListState>();

  void loadNextImage() {
    if (imageUrls.isEmpty) return; // Handle empty list case

    _myList.currentState!.removeItem(0, (context, animation) {
      return ListItem(
        imageUrl: selectedUrl,
        animation: animation,
        close: true,
      );
    }, duration: duration);

    setState(() {
      isFirstLoad = false;
      prevUrl = selectedUrl;
      selectedUrl = imageUrls.removeAt(0);
    });

    imageUrls.add(selectedUrl);
    _myList.currentState!.insertItem(imageUrls.length - 1);
  }

  @override
  void initState() {
    super.initState();
    selectedUrl = imageUrls.isNotEmpty ? imageUrls.last : ''; // Safe check
    prevUrl = selectedUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: NetworkImage(prevUrl),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final maxWidth = c.maxWidth;
            final maxHeight = c.maxHeight;
            final left = maxWidth * .45;
            final top = maxHeight * .54;

            return Stack(
              children: [
                ExpandableItem(
                  key: ObjectKey(selectedUrl),
                  imageUrl: selectedUrl,
                  startExpanded: isFirstLoad,
                  initialPosition: Rect.fromLTWH(
                    left,
                    top,
                    listItemSize.width,
                    listItemSize.height,
                  ),
                ),
                Positioned(
                  left: left,
                  top: top,
                  right: 0,
                  height: listItemSize.height,
                  child: AnimatedList(
                    key: _myList,
                    initialItemCount: imageUrls.length,
                    scrollDirection: Axis.horizontal,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index, Animation<double> animation) {
                      return ListItem(
                        imageUrl: imageUrls[index],
                        animation: animation,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.sync),
        onPressed: loadNextImage,
      ),
    );
  }
}

class ExpandableItem extends StatefulWidget {
  final String imageUrl;
  final Rect initialPosition;
  final bool startExpanded;

  const ExpandableItem({
    required Key key,
    required this.imageUrl,
    required this.initialPosition,
    this.startExpanded = false,
  }) : super(key: key);

  @override
  _ExpandableItemState createState() => _ExpandableItemState();
}

class _ExpandableItemState extends State<ExpandableItem>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<Rect> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: duration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.of(context).size;
    animation = RectTween(
      begin: widget.startExpanded
          ? Rect.fromLTRB(0, 0, 0, 0)
          : widget.initialPosition,
      end: Rect.fromLTWH(0, 0, mq.width, mq.height),
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.linearToEaseOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted && !widget.startExpanded) controller.forward();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double radius = animation.value.top.clamp(0.0, 16.0);
        return Positioned(
          top: animation.value.top,
          left: animation.value.left,
          width: animation.value.width,
          height: animation.value.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                image: DecorationImage(
                  image: NetworkImage(widget.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ListItem extends StatelessWidget {
  final String imageUrl;
  final Animation<double> animation;
  final bool close;

  const ListItem({
    required this.imageUrl,
    required this.animation,
    this.close = false,
  });

  @override
  Widget build(BuildContext context) {
    final margin = EdgeInsets.only(right: 24);

    if (close) {
      return SizeTransition(
        axis: Axis.horizontal,
        sizeFactor: animation,
        child: Container(
          width: listItemSize.width,
          height: listItemSize.height,
          margin: margin,
        ),
      );
    }

    return Container(
      width: listItemSize.width,
      height: listItemSize.height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
