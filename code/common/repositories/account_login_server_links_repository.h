#pragma once

#include "common/repositories/base/base_account_login_server_links_repository.h"

#include "common/database.h"
#include "common/strings.h"

class AccountLoginServerLinksRepository: public BaseAccountLoginServerLinksRepository {
public:

    /**
     * This file was auto generated and can be modified and extended upon
     *
     * Base repository methods are automatically
     * generated in the "base" version of this repository. The base repository
     * is immutable and to be left untouched, while methods in this class
     * are used as extension methods for more specific persistence-layer
     * accessors or mutators.
     *
     * Base Methods (Subject to be expanded upon in time)
     *
     * Note: Not all tables are designed appropriately to fit functionality with all base methods
     *
     * InsertOne
     * UpdateOne
     * DeleteOne
     * FindOne
     * GetWhere(std::string where_filter)
     * DeleteWhere(std::string where_filter)
     * InsertMany
     * All
     *
     * Example custom methods in a repository
     *
     * AccountLoginServerLinksRepository::GetByZoneAndVersion(int zone_id, int zone_version)
     * AccountLoginServerLinksRepository::GetWhereNeverExpires()
     * AccountLoginServerLinksRepository::GetWhereXAndY()
     * AccountLoginServerLinksRepository::DeleteWhereXAndY()
     *
     * Most of the above could be covered by base methods, but if you as a developer
     * find yourself re-using logic for other parts of the code, its best to just make a
     * method that can be re-used easily elsewhere especially if it can use a base repository
     * method and encapsulate filters there
     */

	// Custom extended repository methods here

	static AccountLoginServerLinks FindByLSCredentials(
		Database& db,
		const std::string& ls_id,
		uint32_t lsaccount_id
	)
	{
		const auto& l = GetWhere(
			db,
			fmt::format(
				"`ls_id` = '{}' AND `lsaccount_id` = {} LIMIT 1",
				Strings::Escape(ls_id),
				lsaccount_id
			)
		);

		if (l.empty()) {
			return NewEntity();
		}

		return l.front();
	}

	static bool CreateLink(
		Database& db,
		int32_t account_id,
		const std::string& ls_id,
		uint32_t lsaccount_id,
		const std::string& login_account_name
	)
	{
		auto results = db.QueryDatabase(
			fmt::format(
				"INSERT IGNORE INTO {} (`account_id`, `ls_id`, `lsaccount_id`, `login_account_name`) "
				"VALUES ({}, '{}', {}, '{}')",
				TableName(),
				account_id,
				Strings::Escape(ls_id),
				lsaccount_id,
				Strings::Escape(login_account_name)
			)
		);

		return results.Success();
	}

};
