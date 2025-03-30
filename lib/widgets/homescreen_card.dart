import 'package:flutter/material.dart';

class HomescreenCard extends StatelessWidget {
  final String title;
  final Widget screen;
  const HomescreenCard({super.key, required this.title, required this.screen});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => screen)),
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          height: 60,
          child: Row(
            children: [
              Hero(
                tag: title,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
