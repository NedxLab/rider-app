import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:client_shared/components/ridy_sheet_view.dart';
import 'package:ridy/l10n/messages.dart';
import 'package:ridy/address/addresses.graphql.dart';
import 'package:ridy/main/order.graphql.dart';
import 'package:ridy/schema.gql.dart';
import '../../address/address_details_view.dart';
import 'package:ridy/location_selection/welcome_card/place_search_sheet_view.dart';
import 'package:ridy/main/bloc/main_bloc.dart';
import 'package:ridy/main/bloc/rider_profile_cubit.dart';
import 'package:client_shared/theme/theme.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:latlong2/latlong.dart';

import '../../address/address_item_view.dart';
import '../../address/address_list_view.dart';
import '../../main/bloc/current_location_cubit.dart';

class WelcomeCardView extends StatelessWidget {
  final Function() onSizeChanged;
  const WelcomeCardView({Key? key, required this.onSizeChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mainBloc = context.read<MainBloc>();
    return RidySheetView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<RiderProfileCubit, Query$GetCurrentOrder$rider?>(
            builder: (context, state) {
              return Text(
                S.of(context).welcome_card_greeting(
                    state?.firstName != null ? " ${state!.firstName}" : ""),
                style: Theme.of(context).textTheme.labelMedium,
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            S.of(context).welcome_card_subtitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 8),
            onPressed: () async {
              final result = await showBarModalBottomSheet(
                  useRootNavigator: true,
                  context: context,
                  builder: (context) => PlaceSearchSheetView(
                      context.read<CurrentLocationCubit>().state));
              if (result == null) return;
              mainBloc.add(ShowPreview(
                  points: result, selectedOptions: [], couponCode: null));
            },
            child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: CustomTheme.neutralColors.shade100,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(
                        Ionicons.search,
                        color: CustomTheme.primaryColors,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(S.of(context).welcome_card_textbox_placeholder,
                        style: Theme.of(context).textTheme.labelLarge)
                  ],
                )),
          ),
          BlocBuilder<RiderProfileCubit, Query$GetCurrentOrder$rider?>(
              builder: (context, state) {
            if (state == null) {
              return const SizedBox();
            }
            return Query$GetAddresses$Widget(options:
                Options$Query$GetAddresses(onComplete: (result, parsedData) {
              WidgetsBinding.instance.addPostFrameCallback(
                (timeStamp) {
                  onSizeChanged();
                },
              );
            }), builder: (result, {refetch, fetchMore}) {
              if (result.isLoading) {
                return const Center(
                  child: CupertinoActivityIndicator(),
                );
              }
              final addresses = result.parsedData != null
                  ? result.parsedData!.riderAddresses
                  : <Query$GetAddresses$riderAddresses>[];
              return Column(children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: addresses
                          .map((address) => WelcomeCardSavedLocationButton(
                              onTap: () {
                                final currentLocation =
                                    context.read<CurrentLocationCubit>().state;
                                if (currentLocation == null) {
                                  showLocationNotDeterminedDialog(context);
                                  return;
                                }
                                context.read<MainBloc>().add(ShowPreview(
                                        points: [
                                          currentLocation,
                                          address.toFullLocation()
                                        ],
                                        selectedOptions: []));
                              },
                              type: address.type,
                              address: address.details,
                              title: address.title))
                          .toList(),
                    ),
                  ),
                ),
                AddressListAddLocationButton(onTap: () async {
                  final currentLocation =
                      context.read<CurrentLocationCubit>().state;
                  await showBarModalBottomSheet(
                      context: context,
                      builder: (_) {
                        return BlocProvider.value(
                            value:
                                BlocProvider.of<CurrentLocationCubit>(context),
                            child: AddressDetailsView(
                                currentLocation: currentLocation));
                      });
                  refetch!();
                })
              ]);
            });
          })
        ],
      ),
    );
  }

  void showLocationNotDeterminedDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(S.of(context).location_not_found_alert_dialog_title),
            content: Text(S.of(context).location_not_found_alert_dialog_body),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child:
                      Text(S.of(context).action_ok, textAlign: TextAlign.end))
            ],
          );
        });
  }
}

extension RiderAddressToFullLocation on Query$GetAddresses$riderAddresses {
  FullLocation toFullLocation() {
    return FullLocation(
        latlng: LatLng(location.lat, location.lng),
        address: details,
        title: title);
  }
}

class WelcomeCardSavedLocationButton extends StatelessWidget {
  final Function() onTap;
  final Enum$RiderAddressType type;
  final String address;
  final String title;

  const WelcomeCardSavedLocationButton(
      {required this.onTap,
      required this.type,
      required this.address,
      Key? key,
      required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 8),
        onPressed: onTap,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AddressListIcon(getAddressTypeIcon(type)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  address,
                  style: Theme.of(context).textTheme.labelMedium,
                )
              ],
            ),
          )
        ]));
  }
}
